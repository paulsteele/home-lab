#!/usr/bin/env python3

"""
Dhall Code Generator
"""

import argparse
import sys
import os
import subprocess
import json
from typing import List, Dict

import git

OUTPUT_FILE_TYPE = "yaml"
PACKAGE_FILE_NAME = "package.json"

RESOURCE_CREATION = r"""
let values = {}

let createResource = ./dhall/k8s/{}/create.dhall

let input = values.common /\ values.{}

in createResource input
"""

MULTIPLE_RESOURCE_CREATION = r"""
let map = ./dhall/dependencies/dhall-lang/Prelude/List/map

let values = {}

let commonType = ./dhall/k8s/common.dhall
let inputType = ./dhall/k8s/{}/input.dhall
let outputType = ./dhall/k8s/{}/output.dhall
let hybridType = commonType //\\ inputType

let createResource = ./dhall/k8s/{}/create.dhall
let createHybrid = \(hybridInput: inputType) ->
  values.common /\ hybridInput

let input = values.{}

let hybrid = map inputType hybridType createHybrid input

in map hybridType outputType createResource hybrid
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

  def _check_dhall_validity(self) -> bool:
    if 'resources' not in self.dhall:
      return False

    if not self.dhall['resources']:
      return False

    if 'singles' in self.dhall['resources'] or 'multiples' in self.dhall['resources']:
      if not self.dhall['resources']['singles'] and not self.dhall['resources']['multiples']:
        return False

    return True

  def _generate_dhall(self) -> bool:
    print("Dhall Resources:")

    status = True

    if not self._check_dhall_validity():
      print(f"WARNING: no resources specified for {self.path}")
      return True

    resources = []

    if 'singles' in self.dhall['resources']:
      for single in self.dhall['resources']['singles']:
        resources.append({'resource': single, 'multiple': False})
    if 'multiples' in self.dhall['resources']:
      for multiple in self.dhall['resources']['multiples']:
        resources.append({'resource': multiple, 'multiple': True})

    for resource_map in resources:
      resource = resource_map['resource']
      is_multiple = resource_map['multiple']

      if is_multiple:
        result = subprocess.run(
          ["dhall-to-yaml", "--omitNull", "--documents"],
          capture_output=True,
          text=True,
          input=MULTIPLE_RESOURCE_CREATION.format(f"./{self.path}/{self.dhall['source']}", resource, resource, resource, resource)
        )
      else:
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

  def _apply_dhall(self) -> bool:
    status = True

    result = subprocess.run(
      ["kubectl", "apply", "-f", f"{self.path}/output"],
      capture_output=True,
      text=True
    )

    if result.returncode != 0:
      print(f"{self.path} ✗")
      print(result.stderr, file=sys.stderr)
      status = False
    else:
      print(f"{self.path} ✓")
      print(result.stdout)

    return status

  def _apply_helm(self) -> bool:
    print("Helm Resources:")

    status = True

    result = subprocess.run(
      ["helm", "install", self.helm['source'], '-n', self.helm['name'], '-f', f"./{self.path}/{self.helm['values']}"],
      capture_output=True,
      text=True
    )

    if result.returncode != 0:
      print(f"{self.helm['name']} ✗")
      print(result.stderr, file=sys.stderr)
      status = False
    else:
      print(f"{self.helm['name']} ✓")
      print(result.stdout)

    return status

  def generate(self) -> bool:
    '''Generates all resources defined in the service'''
    status = True

    print(f"Creating Resources for {self.path}:")

    if self.dhall:
      status = self._generate_dhall() and status

    return status

  def apply(self) -> bool:
    '''Applies all resources defined in the service'''
    status = True

    if self.dhall:
      stats = self._apply_dhall() and status

    if self.helm:
      status = self._apply_helm() and status

    return status

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

def parse_args(argv: List[str]):
  parser = argparse.ArgumentParser(prog="Resource Generator")
  subparsers = parser.add_subparsers(help="commands", dest='command')

  gen = subparsers.add_parser('generate', help="Generate configurations")
  app = subparsers.add_parser('apply', help="Applies configurations")
  subparsers.add_parser('init', help="Initializes dependencies")

  gen.add_argument("directories", nargs="*")
  app.add_argument("directories", nargs="*")

  return parser.parse_args()

def main(argv: List[str]) -> None:
  '''entrypoint of the program'''
  args = parse_args(argv)

  if args.command == 'init':
    init()
    sys.exit(0)

  services = []

  for directory in args.directories:
    services.append(Service(directory))

  status = True

  if args.command == 'generate':
    for service in services:
      status = service.generate() and status

  if args.command == 'apply':
    for service in services:
      status = service.apply() and status

  if not status:
    sys.exit(1)

if __name__ == "__main__":
  main(sys.argv)
