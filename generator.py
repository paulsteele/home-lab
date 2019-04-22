#!/usr/bin/env python3

"""
Dhall Code Generator
"""

import argparse
import sys
import os
import subprocess
import json
import re
from typing import List, Dict

import git

OUTPUT_FILE_TYPE = "yaml"
PACKAGE_FILE_NAME = "package.json"

RESOURCE_CREATION = r"""
let values = {0}

let createResource = ./dhall/k8s/{1}/create.dhall

let input = values.common /\ values.{2}

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

  def _check_dhall_validity(self, key) -> bool:
    if key not in self.dhall:
      return False

    return bool(self.dhall[key])

  def _run_dhall(self, resource: str, secret_text: str = "") -> bool:
    # for strings that look like "resource_type-03", extract "resource_type"
    matches = re.search(r'([^-\s]+)(-\d+)?', resource)

    if not matches:
      print(f"Could not determine resource type for {resource}")
      print(f"{resource} ✗")
      return False

    resource_type = matches.group(1)

    result = subprocess.run(
      ["dhall-to-yaml", "--omitNull", "--documents"],
      capture_output=True,
      text=True,
      input=RESOURCE_CREATION.format(f"./{self.path}/{self.dhall['source']}", resource_type, resource)
    )

    if result.returncode != 0:
      print(f"{resource} ✗")
      print(result.stderr, file=sys.stderr)
      return False

    output_file_name = f"{resource}.{OUTPUT_FILE_TYPE}"

    if not os.path.exists(f"{self.path}/output"):
      os.makedirs(f"{self.path}/output")

    with open(f"{self.path}/output/{output_file_name}", 'w') as output_file:
      output_file.write(result.stdout)

    print(f"{resource} ✓")

    return True

  def _generate_dhall(self) -> bool:
    print("Dhall Resources:")

    status = True

    if not self._check_dhall_validity('resources'):
      print(f"WARNING: no resources specified for {self.path}")
      return True

    for resource in self.dhall['resources']:
      status = self._run_dhall(resource) and status

    return status

  def _generate_secret(self) -> bool:
    print("Dhall Secrets:")

    status = True

    if not self._check_dhall_validity('secrets'):
      print(f"WARNING: no secrets specified for {self.path}")
      return True

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

  def generate(self, generate_secrets=False) -> bool:
    '''Generates all resources defined in the service'''
    status = True

    print(f"Creating Resources for {self.path}:")

    if generate_secrets:
      status = self._generate_secret() and status

    if self.dhall:
      status = self._generate_dhall() and status

    return status

  def apply(self) -> bool:
    '''Applies all resources defined in the service'''
    status = True
    if self.dhall:
      status = self._apply_dhall() and status

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

  gen.add_argument("--secrets", action='store_true', help="generates secrets")
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
      status = service.generate(args.secrets) and status

  if args.command == 'apply':
    for service in services:
      status = service.apply() and status

  if not status:
    sys.exit(1)

if __name__ == "__main__":
  main(sys.argv)
