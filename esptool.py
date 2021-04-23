#!/bin/sh
IDF_PATH=$(dirname $(dirname $(dirname $(dirname $0))))
export IDF_PATH
echo "IDF_PATH is $IDF_PATH"
echo esptool.py $*
ACTIVATE=$IDF_PATH/venv/bin/activate
if [ ! -f $ACTIVATE ]; then
  python3 -m venv $IDF_PATH/venv
  if [ ! -f $ACTIVATE ]; then
    echo "Error: Could not create virtual env, please install python3 on your computer and make sure it is in your system's path"
    exit 1
  fi
fi
. $IDF_PATH/venv/bin/activate
if [ -z "$(python3 -m pip list | grep pyserial )" ]; then
  python3 -m pip install --upgrade pip
  python3 -m pip install -r $IDF_PATH/requirements.txt
fi
export PATH=$IDF_PATH/tools:$PATH
python3 $IDF_PATH/components/esptool_py/esptool/esptool-orig.py $*
