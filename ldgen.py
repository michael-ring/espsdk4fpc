#!/bin/sh
echo $0
echo $*
IDF_PATH=$(dirname $(dirname $(dirname $0)))
export IDF_PATH
echo $IDF_PATH
ACTIVATE=$IDF_PATH/venv/bin/activate
if [ ! -f $ACTIVATE ]; then
  python3 -m venv $IDF_PATH/venv
  if [ ! -f $ACTIVATE ]; then
    echo "Error: Could not create virtual env, please install python3 on your computer and make sure it is in your system's path"
    exit 1
  fi
fi
. $IDF_PATH/venv/bin/activate
if [ ! -f $IDF_PATH/venv/grinsekatz ]; then
  python3 -m pip install --upgrade pip
  python3 -m pip install -r $IDF_PATH/requirements.txt
fi
#pushd $IDF_PATH
#. ./export.sh
#popd
export PATH=$IDF_PATH/tools:$PATH
python3 $IDF_PATH/tools/ldgen/ldgen-orig.py $*
