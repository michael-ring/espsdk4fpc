#!/usr/bin/env python3
from __future__ import print_function
import os
import sys
import subprocess
from pathlib import Path
import importlib.util

def installVenv():
  try:
    print("Checking pip...")
    subprocess.run(['pip3', '--version'])
  except Exception as e:
    print("python3 module 'pip' is not installed, please fix")
    print("on debian like linux: sudo apt-get install python3-pip")
    print("on redhat like linux: sudo dnf install python3-pip")
    sys.exit(-1)
  #try:
  #  print("Checking venv...")
  #  subprocess.check_output(['python3', '-m','venv','-h'],text=True)
  #except Exception as e:
  #  print("python3 module 'venv' is not installed, please fix")
  #  print("on debian like linux: sudo apt-get install python3-venv")
  #  print("on redhat like linux: sudo dnf install python3-venv")
  #  sys.exit(-1)
  try:
    print("Checking virtualenv...")
    subprocess.check_output(['python3', '-m','virtualenv','-h'],text=True)
  except Exception as e:
    print("python3 module 'virtualenv' is not installed, please fix")
    print("on debian like linux: sudo apt-get install python3-virtualenv")
    print("on redhat like linux: sudo dnf install python3-virtualenv")
    sys.exit(-1)
  #try:
  #  print("Creating venv...")
  #  subprocess.run(['python3', '-m', 'venv', '--clear','--upgrade-deps',str(Path(__file__).parent / 'venv')])
  #except Exception as e:
  #  print("The installation of the venv failed, check that you are connected to the internet")
  #  print("otherwise please create an issue on https://github.com/michael-ring/espsdk4fpc/issues")
  #  print()
  #  sys.exit(-1)
  try:
    print("Creating virtualenv...")
    subprocess.run(['python3', '-m', 'virtualenv', '--clear',str(Path(__file__).parent / 'venv')])
  except Exception as e:
    print("The installation of the virtualenv failed, check that you are connected to the internet")
    print("otherwise please create an issue on https://github.com/michael-ring/espsdk4fpc/issues")
    print()
    sys.exit(-1)
  print("venv setup complete")

  print("venv setup complete")

def installRequirements():
  print("Checking wheel...")
  if importlib.util.find_spec('wheel') == None:
    try:
      subprocess.run(['pip3', 'install', 'wheel'])
    except Exception as e:
      print("The installation of the wheel failed, check that you are connected to the internet")
      print("otherwise please create an issue on https://github.com/michael-ring/espsdk4fpc/issues")
      print()
      sys.exit(-1)

  try:
    subprocess.run(['pip3', 'install', 'esptool'])
  except Exception as e:
    print("The installation of the esptool failed, check that you are connected to the internet")
    print("otherwise please create an issue on https://github.com/michael-ring/espsdk4fpc/issues")
    print()
    sys.exit(-1)
  print("requirements setup complete")

if 'VIRTUAL_ENV' not in os.environ:
  if (sys.version_info.major < 3 ) or (sys.version_info.major == 3 and sys.version_info.minor < 8 ):
    print("python is outdated, minimum version required is python3.8")
    print("on macos : please download latest python3 from https://www.python.org/ and install")
    print("on windows : please download latest python3 from https://www.python.org/ and install")
    print("on debian like linux: sudo apt-get install python3 python3-pip python3-venv")
    print("on redhat like linux: sudo dnf install python3 python3-pip python3-venv")
    sys.exit(-1)
  venv = Path(__file__).parent / 'venv'
  venvPython = venv / 'bin' / 'python3'

  try:
    output = subprocess.check_output([venvPython, "--version"], text=True)
  except Exception as e:
    installVenv()
  os.environ['VIRTUAL_ENV'] = str(venv)
  os.execv(str(venvPython),[str(venvPython)] + [__file__] + sys.argv[1:])
else:
  print("Args:")
  print(sys.argv)
  activate_this_file = sys.executable.replace("python3","activate_this.py")
  exec(open(activate_this_file).read(), {'__file__': activate_this_file})

  realesptool=Path(sys.executable).parent / 'esptool.py'
  if not realesptool.exists():
    installRequirements()
  os.execv(str(sys.executable),[str(sys.executable)] + [str(realesptool)] + sys.argv[1:])
