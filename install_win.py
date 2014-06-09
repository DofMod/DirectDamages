#!python

from __future__ import print_function

import json
import os
import os.path as op
import re
import shutil
import subprocess
import sys

verbose = False

moduleName = "DirectDamages"
authorName = "Relena"
contributorsName = [] # List of String
descriptionShort = "Compute and display the damages of your spells/weapon"
description = "Compute and display the damages of your spells/weapon"
categories = "Fight" # CSV format

srcPath = "."
dstPath = op.normpath(op.join(os.environ['PROGRAMFILES(X86)'], "Dofus2Beta/app/ui", authorName + "_" + moduleName))

def copyFile(filename):
	if verbose:
		print("Copying file : {}".format(filename), file=sys.stderr)

	shutil.copyfile(op.normpath(op.join(srcPath, filename)), op.normpath(op.join(dstPath, filename)))

def copyDir(dirname):
	if verbose:
		print("Copying directory : {}".format(dirname), file=sys.stderr)

	shutil.rmtree(op.normpath(op.join(dstPath, dirname)), 1)
	shutil.copytree(op.normpath(op.join(srcPath, dirname)), op.normpath(op.join(dstPath, dirname)))

def makeDir(dirname):
	if op.isdir(dirname):
		return
	
	if verbose:
		print("Module path doesn't exists, creating it :\n -  {}".format(dirname), file=sys.stderr)

	os.makedirs(dirname)

def getVersion():
	command = ['git', 'describe', '--long']
	out = subprocess.Popen(command, stdout=subprocess.PIPE)
	(sout, serr) = out.communicate()

	result = re.match(r"v(-?[0-9|\.]+)_(-?[0-9|\.]+)-(-?[0-9|\.]+)", sout)
	if result is None:
		raise RuntimeError("Wrong tag format")

	return {"dofusVersion" : result.group(1), "version" : result.group(2), "revision" : result.group(3)}

def getReleaseDate():
	command = ['git', 'log', '--tags', '--simplify-by-decoration', '-1', '--pretty=%ai']
	out = subprocess.Popen(command, stdout=subprocess.PIPE)
	(sout, serr) = out.communicate()

	result = re.match(r"(-?[0-9|\.]+)-(-?[0-9|\.]+)-(-?[0-9|\.]+)", sout)
	if result is None:
		raise RuntimeError("Wrong date format")

	return result.group(0)

def updateModFile(version, date):
	if not op.isfile(op.normpath(op.join(srcPath, "mod.info"))):
		return

	with open(op.normpath(op.join(srcPath, "mod.info")), "r") as file:
		data = file.read()
		data = data.replace("${name}", moduleName)
		data = data.replace("${author}", authorName)
		data = data.replace("${dofusVersion}", version["dofusVersion"])
		data = data.replace("${version}", version["version"])
		data = data.replace("${tag}", "v" + version["dofusVersion"] + "_" + version["version"])
		data = data.replace("${date}", date)
		data = data.replace("${contributors}", json.dumps(contributorsName))
		data = data.replace("${descriptionShort}", descriptionShort)
		data = data.replace("${categories}", categories)
		with open(op.normpath(op.join(srcPath, "mod.json")), "w") as outFile:
			outFile.write(data)

def updateDmFile(version):
	if not op.isfile(op.normpath(op.join(srcPath, "dm.info"))):
		return

	with open(op.normpath(op.join(srcPath, "dm.info")), "r") as file:
		data = file.read()
		data = data.replace("${name}", moduleName)
		data = data.replace("${author}", authorName)
		data = data.replace("${dofusVersion}", version["dofusVersion"])
		data = data.replace("${version}", version["version"])
		data = data.replace("${description}", description)
		data = data.replace("${descriptionShort}", descriptionShort)
		with open(op.normpath(op.join(srcPath, authorName + "_" + moduleName + ".dm")), "w") as outFile:
			outFile.write(data)

if __name__ == '__main__':
	if len(sys.argv) > 1:
		if "usage" in sys.argv[1] or "help" in sys.argv[1]:
			print("Usage : {} [verbose]".format(sys.argv[0]))
			exit()

		if sys.argv[1] == "verbose":
			verbose = True

	makeDir(dstPath)

	version = getVersion()
	date = getReleaseDate()

	updateModFile(version, date)
	updateDmFile(version)

	copyFile(authorName + "_" + moduleName + ".dm")
	copyFile(moduleName + ".swf")
	# copyFile("shortcuts.xml")
	# copyFile("icon.png")
	# copyDir("css")
	copyDir("xml")
	copyDir("chunks")
	# copyDir("lang")
