#!/usr/bin/env python3

"""
Dhall Code Generator
"""

import sys
import os
import subprocess
from typing import List

import git

OUTPUT_FILE_TYPE = "yaml"
INPUT_FILE = "values.dhall"
DHALL_COMMENT = '--'

RESOURCE_CREATION = r"""
let values = {}

let createResource = ./dhall/k8s/{}/create.dhall

let input = values.common /\ values.{}

in createResource input
"""

DEPENDENCIES = {
    'dhall-kubernetes' : 'https://github.com/dhall-lang/dhall-kubernetes.git',
    'prelude' : 'https://github.com/dhall-lang/dhall-lang.git'
}

def handle_service(path: str) -> bool:
  '''Takes a path to a directory that contains dhall configurations and generates yaml from them'''
  items = get_actionable_resources(path)

  if not items:
    print("{} has no actionable files. Skipping...".format(path))
    return False

  print("Generating configs for {}...\n".format(path))
  for item in items:
    result = subprocess.run(
      ["dhall-to-yaml", "--omitNull"],
      capture_output=True,
      text=True,
      input=RESOURCE_CREATION.format(f"./{path}/{INPUT_FILE}", item, item)
    )

    if result.returncode != 0:
      print("{}/{} ✗".format(path, item))
      print(result.stderr, file=sys.stderr)
      return False
    output_file_name = f"{item}.{OUTPUT_FILE_TYPE}"

    if not os.path.exists("{}/output".format(path)):
      os.makedirs("{}/output".format(path))

    with open("{}/output/{}".format(path, output_file_name), 'w') as output_file:
      output_file.write(result.stdout)

    print("{}/{} ✓".format(path, item))

  print("")
  return True

def get_actionable_resources(path: str) -> List[str]:
  '''takes a path and gets a list of resources that can be generated'''
  items: List[str] = []

  try:
    with open(f"{path}/{INPUT_FILE}") as file:
      line = file.readline()
  except FileNotFoundError:
    print(f"Could not find {INPUT_FILE} in {path}")

  if line.startswith(DHALL_COMMENT):
    line = line[len(DHALL_COMMENT):len(line)]
    items = line.split(",")
    items = list(filter(None, map(lambda resource: resource.strip(), items)))
  else:
    print(f"WARNING: No resource list comment found at top of {path}/{INPUT_FILE}")

  return items

def should_init(argv: List[str]) -> bool:
  '''Determines whether initialization needs to occur'''
  return "--init" in argv

def init():
  '''Initializes the generator, by pulling all needed dependencies'''

  for key, value in DEPENDENCIES.items():
    path = "dhall/dependencies"
    if not os.path.exists(path):
      os.makedirs((path))
    repository = git.cmd.Git(path)
    try:
      print("Checking {}".format(key))
      repository.clone(value)
      print("Cloned {}".format(key))
    except git.GitCommandError:
      repository.pull()
      print("Pulled {}".format(key))
  print("Dependencies pulled...")

def get_paths(argv: List[str]) -> List[str]:
  '''from a list of arguments, obtains which directories should be generated'''

  if len(argv) < 2:
    print("usage: ./generator.py [service]")
    sys.exit(1)

  argv.pop(0)
  return argv

def main(argv: List[str]) -> None:
  '''entrypoint of the program'''
  if should_init(argv):
    init()
  else:
    paths = get_paths(argv)

    did_error = False

    for path in paths:
      if not handle_service(path):
        did_error = True

    if did_error:
      sys.exit(1)

if __name__ == "__main__":
  main(sys.argv)
