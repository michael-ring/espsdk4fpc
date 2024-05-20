#!/bin/sh

createVenv()
{
  python3 -I -s --version 2>/dev/null >/dev/null
  if [ "$?" != 0 ]; then
    echo "python3 is not installed"
    echo "on macos : please download latest python3 from https://www.python.org/ and install"
    echo "on debian like linux: sudo apt-get install python3 python3-pip python3-venv"
    echo "on redhat like linux: sudo dnf install python3 python3-pip python3-venv"
    exit 1
  fi
  python3 -I -m pip -h 2>&1 >/dev/null
  if [ "$?" != 0 ]; then
    echo "python3 module 'pip' is not installed, please fix"
    echo "on debian like linux: sudo apt-get install python3-pip"
    echo "on redhat like linux: sudo dnf install python3-pip"
    exit 1
  fi
  python3 -I -m venv -h 2>&1 >/dev/null
  if [ "$?" != 0 ]; then
    echo "python3 module 'venv' is not installed, please fix"
    echo "on debian like linux: sudo apt-get install python3-venv"
    echo "on redhat like linux: sudo dnf install python3-venv"
    exit 1
  fi

  rm -rf $IDF_PATH/venv

  python3 -m venv $IDF_PATH/venv
  if [ ! -f $ACTIVATE ]; then
    echo "Error: Could not create virtual env"
    echo "please create an issue on https://github.com/michael-ring/espsdk4fpc/issues and paste the following output:"
    python3 -m venv $IDF_PATH/venv
    exit 1
  fi
  . $IDF_PATH/venv/bin/activate
  python3 -m pip install --upgrade pip
  if [ -f $IDF_PATH/requirements.txt ]; then
    python3 -m pip install -r $IDF_PATH/requirements.txt
    if [ "$?" != 0 ]; then
      echo "Setting up modules for venv failed"
      echo "please create an issue on https://github.com/michael-ring/espsdk4fpc/issues and paste the following output:"
      python3 -m pip install -r $IDF_PATH/requirements.txt
      exit 1
    fi
  else
    python3 -m pip install ldgen
    if [ "$?" != 0 ]; then
      echo "Setting up modules for venv failed"
      echo "please create an issue on https://github.com/michael-ring/espsdk4fpc/issues and paste the following output:"
      python3 -m pip install ldgen
      exit 1
  fi
}

IDF_PATH=$(dirname $(dirname $(dirname $0)))
echo "(1023) IDF_PATH is $IDF_PATH"
export IDF_PATH
if [ ! -f $IDF_PATH/venv/bin/activate ]; then
  # we do not have a venv, create it
  createVenv
fi
ls -Ll $IDF_PATH/venv/bin/python3 2>&1 | grep "1" >/dev/null
if [ "$?" != 0 ]; then
  # venv is outdated and points to a deleted version of python
  echo "(1023) refreshing outdated venv"
  createVenv
fi

. $IDF_PATH/venv/bin/activate
PATH=$IDF_PATH/tools:$PATH
export PATH

python3 $IDF_PATH/tools/ldgen/ldgen-orig.py -h 2>/dev/null >/dev/null
if [ "$?" != 0 ]; then
  # something ist wrong, refresh the venv...
  echo "(1023) refreshing outdated venv, if you see this on every compile then create an issue on https://github.com/michael-ring/espsdk4fpc/issues"
  createVenv
fi
python3 $IDF_PATH/tools/ldgen/ldgen-orig.py "$@"
