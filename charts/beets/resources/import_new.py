"""Import only music files not yet present in the Beets catalog."""

import fnmatch
import os
from pathlib import Path
import sqlite3
import subprocess
import sys

import yaml


MUSIC_EXTENSIONS = frozenset(
    b".aac .aif .aiff .ape .asf .dsf .flac .m4a .m4b .mp3 .mp4 .mpc .oga .ogg .opus .wav .wma .wv".split()
)
IMPORT_BATCH_SIZE = 64


def cataloged_paths(database: str, root: str) -> set[bytes]:
    if not os.path.exists(database):
        return set()

    music_root = os.fsencode(os.path.abspath(root))
    paths = set()
    with sqlite3.connect(Path(database).resolve().as_uri() + "?mode=ro", uri=True) as connection:
        for (stored_path,) in connection.execute("SELECT path FROM items"):
            path = os.fsencode(stored_path)
            if not os.path.isabs(path):
                path = os.path.join(music_root, path)
            paths.add(os.path.normpath(path))
    return paths


def new_music_paths(root: str, known: set[bytes], ignore: list[str], ignore_hidden: bool):
    root_path = os.fsencode(os.path.abspath(root))
    if not os.path.isdir(root_path):
        raise NotADirectoryError(root)

    patterns = [os.fsencode(pattern) for pattern in ignore]

    def ignored(name: bytes) -> bool:
        return (ignore_hidden and name.startswith(b".")) or any(
            fnmatch.fnmatch(name, pattern) for pattern in patterns
        )

    def fail_on_walk_error(error: OSError) -> None:
        raise error

    for directory, subdirs, files in os.walk(root_path, onerror=fail_on_walk_error):
        subdirs[:] = [name for name in subdirs if not ignored(name)]
        for name in files:
            if ignored(name) or os.path.splitext(name)[1].lower() not in MUSIC_EXTENSIONS:
                continue
            path = os.path.join(directory, name)
            if path not in known and os.path.isfile(path):
                yield path


def import_new(beet: str, config_path: str) -> None:
    with open(config_path, encoding="utf-8") as config_file:
        config = yaml.safe_load(config_file)

    database = config["library"]
    known = cataloged_paths(database, config["directory"])
    pending = list(
        new_music_paths(
            config["directory"], known, config.get("ignore", []),
            config.get("ignore_hidden", False),
        )
    )
    print(f"Cataloged tracks: {len(known)}; new music files: {len(pending)}", flush=True)

    for start in range(0, len(pending), IMPORT_BATCH_SIZE):
        batch = pending[start : start + IMPORT_BATCH_SIZE]
        subprocess.run(
            [beet, "-c", config_path, "import", "-A", "-C", "-M", "-W", "-q", "-s", "-p", *batch],
            check=True,
        )


if __name__ == "__main__":
    import_new(sys.argv[1], sys.argv[2])
