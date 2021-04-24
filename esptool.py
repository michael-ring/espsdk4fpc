#!/bin/sh
IDF_PATH=$(dirname $(dirname $(dirname $(dirname $0))))
export IDF_PATH
echo "(1023) IDF_PATH is $IDF_PATH"

python3 --version 2>/dev/null >/dev/null
if [ "$?" != 0 ]; then
  echo "python3 is not installed"
  echo "on macos : please download latest python3 from https://www.python.org/ and install"
  echo "on debian like linux: sudo apt-get install python3 python3-pip python3-venv"
  echo "on redhat like linux: sudo dnf install python3 python3-pip python3-venv"
  exit 1
fi
python3 -c 'help("modules")' | grep -w pip 2>&1 >/dev/null
if [ "$?" != 0 ]; then
  echo "python3 module 'pip' is not installed, please fix"
  echo "on debian like linux: sudo apt-get install python3-pip"
  echo "on redhat like linux: sudo dnf install python3-pip"
  exit 1
fi
python3 -c 'help("modules")' | grep -w venv 2>&1 >/dev/null
if [ "$?" != 0 ]; then
  echo "python3 module 'venv' is not installed, please fix"
  echo "on debian like linux: sudo apt-get install python3-venv"
  echo "on redhat like linux: sudo dnf install python3-venv"
  exit 1
fi

ACTIVATE=$IDF_PATH/venv/bin/activate
if [ ! -f $ACTIVATE ]; then
  python3 -m venv $IDF_PATH/venv
  if [ ! -f $ACTIVATE ]; then
    echo "Error: Could not create virtual env"
    echo "please create an issue on https://github.com/michael-ring/espsdk4fpc/issues and paste the following output:"
    python3 -m venv $IDF_PATH/venv
    exit 1
  fi
fi

ls -Ll $IDF_PATH/venv/bin/python3 2>&1 | grep "1" >/dev/null
if [ "$?" != 0 ]; then
  # venv is outdated and points to a deleted version of python
  echo "(1023) refreshing outdated venv"
  rm -rf $IDF_PATH/venv
  python3 -m venv $IDF_PATH/venv
  if [ ! -f $ACTIVATE ]; then
    echo "Error: Could not create virtual env"
    echo "please create an issue on https://github.com/michael-ring/espsdk4fpc/issues and paste the following output:"
    python3 -m venv $IDF_PATH/venv
    exit 1
  fi
fi

. $IDF_PATH/venv/bin/activate

if [ -z "$(python3 -m pip list | grep cryptography )" ]; then
  python3 -m pip install --upgrade pip
  python3 -m pip install -r $IDF_PATH/requirements.txt
fi

python3 -c 'help("modules")' | grep -w cryptography >/dev/null
if [ "$?" != 0 ]; then
  echo "Setting up modules for venv failed"
  echo "please create an issue on https://github.com/michael-ring/espsdk4fpc/issues and paste the following output:"
  python3 -m pip install -r $IDF_PATH/requirements.txt
  exit 1
fi

export PATH=$IDF_PATH/tools:$PATH
python3 $IDF_PATH/components/esptool_py/esptool/esptool-orig.py "$@"
