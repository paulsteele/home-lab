#! /usr/bin/env python3
import sys, getopt, os, subprocess, git
from typing import List

OUTPUT_FILE_TYPE = "yaml"
INPUT_FILE = "values.dhall"
DHALL_COMMENT = '--'

RESOURCE_CREATION = """
let values = {}

let createResource = ./dhall/k8s/{}/create.dhall

let input = values.common /\ values.{}

in createResource input
"""

DEPENDENCIES = {
  'dhall-kubernetes' : 'https://github.com/dhall-lang/dhall-kubernetes.git',
  'prelude' : 'https://github.com/dhall-lang/dhall-lang.git'
}

def handleService(path : str) -> bool:
  items = getActionableResources(path)

  if len(items) < 1:
    print("{} has no actionable files. Skipping...".format(path))
    return False
  
  print("Generating configs for {}...\n".format(path))
  for item in items:
    
    result = subprocess.run(["dhall-to-yaml", "--omitNull"], capture_output=True, text=True , input=RESOURCE_CREATION.format(f"./{path}/{INPUT_FILE}", item, item))
    if result.returncode != 0:
      print("{}/{} ✗".format(path, item))
      print(result.stderr, file=sys.stderr)
      return False
    outputFileName = f"{item}.{OUTPUT_FILE_TYPE}"

    if not os.path.exists("{}/output".format(path)):
      os.makedirs("{}/output".format(path))

    with open("{}/output/{}".format(path, outputFileName), 'w') as outputFile:
      outputFile.write(result.stdout)
    
    print("{}/{} ✓".format(path, item))
  
  print("")
  return True

def getActionableResources(path: str) -> List[str]:
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

def main(argv: List[str]) -> None:
  if (shouldInit(argv)):
    init()
  else :
    paths = getPaths(argv)

    didError = False

    for path in paths:
      if not handleService(path):
        didError = True

    if didError:
      sys.exit(1)

def shouldInit(argv: List[str]) -> bool:
  return "--init" in argv

def init():
  for key, value in DEPENDENCIES.items():
    path = "dhall/dependencies"
    if not os.path.exists(path):
      os.makedirs((path))
    repo = git.cmd.Git(path)
    try:
      print("Checking {}".format(key))
      repo.clone(value)
      print("Cloned {}".format(key))
    except git.exc.GitCommandError:
      repo.pull()
      print("Pulled {}".format(key))
  print("Dependencies pulled...")

def getPaths(argv: List[str]) -> List[str]:
  if len(argv) < 2:
    print("usage: ./generator.py [service]")
    sys.exit(1)

  argv.pop(0)
  return argv

if __name__ == "__main__":
  main(sys.argv)