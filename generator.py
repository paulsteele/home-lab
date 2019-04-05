#!/usr/bin/env python3

"""
Dhall Code Generator
"""

import sys
import os
import subprocess
import json
from typing import List

import git

OUTPUT_FILE_TYPE = "yaml"
PACKAGE_FILE_NAME = "package.json"

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

class Service:
  '''Representation of generatable resources'''

  path: str

  def __init__(self, path):
    try:
      with open(f"{path}/{PACKAGE_FILE_NAME}") as json_data:
        package = json.load(json_data)
    except FileNotFoundError:
      print(f"Could not find {PACKAGE_FILE_NAME} in {path}")
      return

    self.path = path

    self.dhall = package['dhall'] if 'dhall' in package else None
    self.helm = package['helm'] if 'helm' in package else None

  def _generate_dhall(self) -> bool:
    print("Dhall Resources:")

    status = True

    if 'resources' not in self.dhall or not self.dhall['resources']:
      print(f"WARNING: no resources specified for {self.path}")
      return True

    for resource in self.dhall['resources']:
      result = subprocess.run(
        ["dhall-to-yaml", "--omitNull"],
        capture_output=True,
        text=True,
        input=RESOURCE_CREATION.format(f"./{self.path}/{self.dhall['source']}", resource, resource)
      )

      if result.returncode != 0:
        print(f"{resource} ✗")
        print(result.stderr, file=sys.stderr)
        status = False
        continue

      output_file_name = f"{resource}.{OUTPUT_FILE_TYPE}"

      if not os.path.exists(f"{self.path}/output"):
        os.makedirs(f"{self.path}/output")

      with open(f"{self.path}/output/{output_file_name}", 'w') as output_file:
        output_file.write(result.stdout)

      print(f"{resource} ✓")

    return status


  def _generate_helm(self) -> bool:
    print("Helm Resources:")
    return True

  def generate(self) -> bool:
    '''Generates all resources defined in the service'''
    status = True

    print(f"Creating Resources for {self.path}:")

    if self.dhall:
      status = self._generate_dhall() and status
    if self.helm:
      status = self._generate_helm() and status

    return status

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

    status = True

    for path in paths:
      service = Service(path)

      status = service.generate() and status

    if not status:
      sys.exit(1)

if __name__ == "__main__":
  main(sys.argv)
