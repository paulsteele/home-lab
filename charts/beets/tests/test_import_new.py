"""Catalog-aware import discovery, without a Kubernetes or NAS dependency."""

import importlib.util
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest.mock import patch

import yaml


SCRIPT = Path(__file__).resolve().parents[1] / "resources" / "import_new.py"
spec = importlib.util.spec_from_file_location("import_new", SCRIPT)
import_new = importlib.util.module_from_spec(spec)
spec.loader.exec_module(import_new)


class ImportNewTest(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory()
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name) / "music"
        self.root.mkdir()
        self.album = self.root / "Existing album"
        self.album.mkdir()
        self.database = Path(self.scratch.name) / "library.db"
        self.config = Path(self.scratch.name) / "config.yaml"
        self.config.write_text(
            yaml.safe_dump({
                "library": str(self.database),
                "directory": str(self.root),
                "ignore": [".*", "*~", "*.m4p"],
                "ignore_hidden": True,
            }),
            encoding="utf-8",
        )

    def track(self, name, folder=None):
        path = (folder or self.album) / name
        path.write_bytes(b"fixture")
        return path

    def create_catalog(self, *paths):
        with sqlite3.connect(self.database) as connection:
            connection.execute("CREATE TABLE items (path BLOB)")
            connection.executemany(
                "INSERT INTO items (path) VALUES (?)",
                [(bytes(path.relative_to(self.root)),) for path in paths],
            )

    def add_catalog_paths(self, *paths):
        with sqlite3.connect(self.database) as connection:
            connection.executemany(
                "INSERT INTO items (path) VALUES (?)",
                [(bytes(path.relative_to(self.root)),) for path in paths],
            )

    def run_import(self):
        with patch.object(import_new.subprocess, "run") as run:
            import_new.import_new("/lsiopy/bin/beet", str(self.config))
        return run.call_args_list

    def test_repeat_run_only_imports_new_tracks_in_existing_directories(self):
        existing = self.track("already.mp3")
        newly_added = self.track("added.FLAC")
        new_album = self.root / "New album"
        new_album.mkdir()
        another_new_track = self.track("another.m4a", new_album)
        self.create_catalog(existing)

        calls = self.run_import()
        self.assertEqual(len(calls), 1)
        self.assertEqual(
            set(calls[0].args[0][11:]),
            {bytes(newly_added), bytes(another_new_track)},
        )
        self.assertEqual(
            calls[0].args[0][0:11],
            ["/lsiopy/bin/beet", "-c", str(self.config), "import", "-A", "-C", "-M", "-W", "-q", "-s", "-p"],
        )
        self.assertTrue(calls[0].kwargs["check"])

        self.add_catalog_paths(newly_added, another_new_track)
        self.assertEqual(self.run_import(), [])

    def test_absolute_catalog_paths_remain_supported(self):
        existing = self.track("already.mp3")
        with sqlite3.connect(self.database) as connection:
            connection.execute("CREATE TABLE items (path BLOB)")
            connection.execute("INSERT INTO items (path) VALUES (?)", (bytes(existing),))

        self.assertEqual(self.run_import(), [])

    def test_empty_catalog_imports_audio_but_not_ignored_or_nonmusic_files(self):
        wanted = self.track("song.mp3")
        self.track("drm.m4p")
        self.track("album.jpg")
        self.track("temporary.mp3~")
        self.track(".hidden.mp3")
        hidden_folder = self.root / ".cache"
        hidden_folder.mkdir()
        self.track("ignored.mp3", hidden_folder)

        calls = self.run_import()
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0].args[0][11:], [bytes(wanted)])

    def test_import_batches_are_bounded(self):
        for index in range(import_new.IMPORT_BATCH_SIZE + 1):
            self.track(f"{index:04}.mp3")
        calls = self.run_import()
        self.assertEqual([len(call.args[0]) - 11 for call in calls], [64, 1])

    def test_broken_catalog_fails_closed(self):
        self.database.write_text("not a database", encoding="utf-8")
        self.track("song.mp3")
        with patch.object(import_new.subprocess, "run") as run:
            with self.assertRaises(sqlite3.DatabaseError):
                import_new.import_new("/lsiopy/bin/beet", str(self.config))
        run.assert_not_called()

    def test_unavailable_music_directory_fails_closed(self):
        self.root.rename(self.root.with_name("unmounted"))
        with patch.object(import_new.subprocess, "run") as run:
            with self.assertRaises(NotADirectoryError):
                import_new.import_new("/lsiopy/bin/beet", str(self.config))
        run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
