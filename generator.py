#! /usr/bin/env python3
import sys, getopt, os, subprocess
from typing import List

ACTIONABLE_PREFIX = "create"
INPUT_FILE_TYPE = "dhall"
OUTPUT_FILE_TYPE = "yaml"

def handleService(path : str) -> bool:
  items = getActionableFiles(path)

  if len(items) < 1:
    print("{} has no actionable files. Skipping...".format(path))
    return False
  
  print("Generating configs for {}...\n".format(path))
  for item in items:
    
    result = subprocess.run(["dhall-to-yaml", "--omitNull"], capture_output=True, text=True , input="[ ./{}/{} ]".format(path, item))
    if result.returncode != 0:
      print("{}/{} ✗".format(path, item))
      print(result.stderr, file=sys.stderr)
      return False
    outputFileName = convertFileName(item)

    if not os.path.exists("{}/output".format(path)):
      os.makedirs("{}/output".format(path))

    with open("{}/output/{}".format(path, outputFileName), 'w') as outputFile:
      outputFile.write(result.stdout)
    
    print("{}/{} ✓".format(path, item))
  
  print("")
  return True
  
def convertFileName(dhallFile: str) -> str:
  return dhallFile.replace(ACTIONABLE_PREFIX, "").replace(INPUT_FILE_TYPE, OUTPUT_FILE_TYPE).lower()

def getActionableFiles(path: str) -> List[str]:
  items: List[str] = []

  if os.path.isdir(path):
    for (dirpath, dirnames, filenames) in os.walk(path):
      for filename in filenames:
        if ACTIONABLE_PREFIX in filename:
          items.append(filename)

  return items

def main(argv: List[str]) -> None:
  paths = getPaths(argv)

  didError = False

  for path in paths:
    if not handleService(path):
      didError = True

  if didError:
    sys.exit(1)

def getPaths(argv: List[str]) -> List[str]:
  if len(argv) < 2:
    print("usage: ./generator.py [service]")
    sys.exit(1)

  argv.pop(0)
  return argv

if __name__ == "__main__":
  main(sys.argv)