#!/bin/sh
IDFVER=4.3.2
RTOSVER=3.4

PV=pv
[ "$1" = "--log" ] && PV="tee buildsdk.log | pv"

[ ! -d esp-idf ] && git clone -b v$IDFVER --recursive https://github.com/espressif/esp-idf.git
[ ! -d ESP8266_RTOS_SDK ] && git clone -b v$RTOSVER --recursive https://github.com/espressif/ESP8266_RTOS_SDK.git

./downloadsources.sh

HOSTISWINDOWS=
HOSTISLINUX=
HOSTISDARWIN=
HOSTISDARWINX86_64=
HOSTISDARWINARM64=
HOSTISLINUXX86_64=
HOSTISLINUXI686=

IDFGCC=xtensa-esp32-elf-gcc8_4_0-esp-2021r2
IDFGCCi686_linux=$IDFGCC-linux-i686.tar.gz
IDFGCCx86_64_linux=$IDFGCC-linux-amd64.tar.gz
IDFGCCx86_64_darwin=$IDFGCC-macos.tar.gz
IDFGCCaarch64_darwin=$IDFGCC-macos.tar.gz

RTOSGCC=xtensa-lx106-elf-gcc8_4_0-esp-2020r3
RTOSGCCi686_linux=$RTOSGCC-linux-i686.tar.gz
RTOSGCCx86_64_linux=$RTOSGCC-linux-amd64.tar.gz
RTOSGCCx86_64_darwin=$RTOSGCC-macos.tar.gz
RTOSGCCaarch64_darwin=$RTOS-macos.tar.gz
IDFGCC=
RTOSGCC=

BUILDDIR=$(pwd)
if [ "$(uname -s)" = "Darwin" ]; then
  HOSTISDARWIN=TRUE
  [ "$(uname -m)" = "x86_64" ] && HOSTISDARWINX86_64=TRUE
  [ "$(uname -m)" = "x86_64" ] && ARCHDIR=x86_64-darwin
  [ "$(uname -m)" = "x86_64" ] && IDFGCC=$IDFGCCx86_64_darwin
  [ "$(uname -m)" = "x86_64" ] && RTOSGCC=$RTOSGCCx86_64_darwin

  [ "$(uname -m)" = "arm64" ]  && HOSTISDARWINARM64=TRUE
  [ "$(uname -m)" = "arm64" ]  && ARCHDIR=aarch64-darwin
  [ "$(uname -m)" = "arm64" ]  && IDFGCC=$IDFGCCx86_64_darwin
  [ "$(uname -m)" = "arm64" ]  && RTOSGCC=$RTOSGCCx86_64_darwin
fi

if [ "$(uname -s)" = "Linux" -a "$CC" != "/usr/src/mxe/usr/bin/x86_64-w64-mingw32.static-gcc" ]; then
  HOSTISLINUX=TRUE
  [ "$(uname -m)" = "x86_64" ] && HOSTISLINUXX86_64=TRUE
  [ "$(uname -m)" = "x86_64" ] && IDFGCC=$IDFGCCx86_64_linux
  [ "$(uname -m)" = "x86_64" ] && RTOSGCC=$RTOSGCCx86_64_linux

  [ "$(uname -m)" = "i686" ] && HOSTISLINUXI686=TRUE
  #[ "$(uname -m)" = "i686" ] && IDFGCC=$IDFGCCi686_linux
  [ "$(uname -m)" = "i686" ] && RTOSGCC=$RTOSGCCi686_linux
  ARCHDIR="$(uname -m)-linux"
fi

if [ "$(uname -s | sed 's,_NT.*$,_NT,g')" = "MINGW32_NT" ]; then
  HOSTISWINDOWS=TRUE
  HOSTISWINDOWSI686=TRUE
  ARCHDIR=i686-win32
fi

if [ "$(uname -s | sed 's,_NT.*$,_NT,g')" = "MINGW64_NT" ]; then
  HOSTISWINDOWS=TRUE
  HOSTISWINDOWSX86_64=TRUE
  ARCHDIR=x86_64-win64
fi

if [ "$CC" = "/usr/src/mxe/usr/bin/x86_64-w64-mingw32.static-gcc" ]; then
  HOSTISWINDOWS=TRUE
  HOSTISWINDOWSX86_64=TRUE
  ARCHDIR=x86_64-win64
fi

if [ "$CC" = "/usr/src/mxe/usr/bin/i686-w64-mingw32.static-gcc" ]; then
  HOSTISWINDOWS=TRUE
  HOSTISWINDOWSI686=TRUE
  ARCHDIR=i686-win64
fi

if [ -z "$IDFGCC" ]; then
  echo "Your platform is currently not supported"
  exit 1
fi

echo "Checking dependencies"
echo $BUILDDIR
echo
if [ "$HOSTISLINUX" = TRUE ]; then
  # Dockercross always needs an install of python3
  [ "$BUILDDIR" = "/work" ] && sudo apt-get install -y pv 2>&1 >/dev/null
  [ "$BUILDDIR" = "/work" ] && sudo apt-get install -y python3 python3-dev python3-pip python3-venv python3-wheel 2>&1 | $PV --line-mode --size=238 --name "apt install   " >/dev/null
fi
pv --help 2>/dev/null >/dev/null
if [ "$?" != 0 ]; then
  echo "pv is not installed, please download install"
  echo "on debian like linux: sudo apt-get install pv"
  echo "on redhat like linux: sudo dnf install pv"
  echo "on mac install homebrew from https://brew.sh and: brew install pv"
  exit 1
fi
python3 --version 2>/dev/null >/dev/null
if [ "$?" != 0 ]; then
  echo "python3 is not installed, please download from https://www.python.org/ and install"
  echo "on debian like linux: sudo apt-get install python3 python3-pip python3-venv"
  echo "on redhat like linux: sudo dnf install python3 python3-pip python3-venv"
  exit 1
fi
python3 -c 'help("modules")' 2>/dev/null | grep -w pip >/dev/null
if [ "$?" != 0 ]; then
  echo "python3 module 'pip' is not installed, please fix"
  echo "on debian like linux: sudo apt-get install python3-pip"
  echo "on redhat like linux: sudo dnf install python3-pip"
  exit 1
fi
python3 -c 'help("modules")' 2>/dev/null | grep -w venv >/dev/null
if [ "$?" != 0 ]; then
  echo "python3 module 'venv' is not installed, please fix"
  echo "on debian like linux: sudo apt-get install python3-venv"
  echo "on redhat like linux: sudo dnf install python3-venv"
  exit 1
fi

python3 -c 'help("modules")' 2>/dev/null | grep -w wheel >/dev/null
if [ "$?" != 0 ]; then
  echo "python3 module 'wheel' is not installed, please fix"
  echo "on debian like linux: sudo apt-get install python3-wheel"
  echo "on redhat like linux: sudo dnf install python3-wheel"
  exit 1
fi

echo
echo "Processing esp-idf"
echo
IDF_PATH=$BUILDDIR/esp-idf
export IDF_PATH

[ -d $BUILDDIR/venv-idf ] && rm -rf $BUILDDIR/venv-idf
[ -d $BUILDDIR/venv-rtos ] && rm -rf $BUILDDIR/venv-rtos

if [ ! -d $BUILDDIR/venv-idf ]; then
  python3 -m venv $BUILDDIR/venv-idf
fi
if [ ! -f $BUILDDIR/venv-idf/bin/activate ]; then
  echo "Could not create virtual environment, must exit"
  exit 1
fi

. $BUILDDIR/venv-idf/bin/activate
python3 -m pip install --upgrade pip 2>/dev/null >/dev/null
python3 -m pip install --upgrade wheel 2>/dev/null >/dev/null
python3 -m pip install -r $BUILDDIR/esp-idf/requirements.txt 2>&1 | $PV --line-mode --size=67 --name "install pydeps" >/dev/null

python3 -c 'help("modules")' 2>/dev/null | grep -w cryptography >/dev/null
if [ "$?" != 0 ]; then
  echo "Setting up modules for venv failed, please report back the following lines:"
  python3 -m pip install -r $BUILDDIR/esp-idf/requirements.txt
  exit 1
fi

OUTPUTDIR=$BUILDDIR/$ARCHDIR
[ -d $OUTPUTDIR ] && rm -rf $OUTPUTDIR
mkdir -p $OUTPUTDIR
mkdir $OUTPUTDIR/bin
mkdir $OUTPUTDIR/lx6

[ -d $BUILDDIR/tmp ] && rm -rf $BUILDDIR/tmp
mkdir $BUILDDIR/tmp
cd $BUILDDIR/tmp
tar zxvf $BUILDDIR/$IDFGCC 2>&1 | $PV --line-mode --size=2035 --name "extract gcc   " >/dev/null
cp xtensa-esp32-elf/bin/* $OUTPUTDIR/bin/
cp -r xtensa-esp32-elf/libexec $OUTPUTDIR/
cp -r xtensa-esp32-elf/xtensa-esp32-elf/lib/* $OUTPUTDIR/lx6/
cp -r xtensa-esp32-elf/lib/gcc/xtensa-esp32-elf/*/* $OUTPUTDIR/lx6/

cp -r $BUILDDIR/esp-idf/components/xtensa/esp32/   $OUTPUTDIR/lx6/
#cp -r $BUILDDIR/esp-idf/components/bt/controller/lib/*.a $OUTPUTDIR/lx6/
cp -r $BUILDDIR/esp-idf/components/esp_wifi/lib/esp32/ $OUTPUTDIR/lx6/
cp -r $BUILDDIR/esp-idf/components/xtensa/esp32/*.a $OUTPUTDIR/lx6/

mkdir -p $OUTPUTDIR/esp-idf-$IDFVER/components
cd $BUILDDIR/esp-idf/components

for pattern in '[kK]config*' '*.lf' '*.info' '*.ld' '*.in' ; do
  find . -type f -name "$pattern" | while read file ; do
    mkdir -p  $OUTPUTDIR/esp-idf-$IDFVER/components/$(dirname $file) 2>/dev/null
    cp $file $OUTPUTDIR/esp-idf-$IDFVER/components/$file
  done
done

cp -r $BUILDDIR/esp-idf/components/esptool_py  $OUTPUTDIR/esp-idf-$IDFVER/components/
mv $OUTPUTDIR/esp-idf-$IDFVER/components/esptool_py/esptool/esptool.py $OUTPUTDIR/esp-idf-$IDFVER/components/esptool_py/esptool/esptool-orig.py
cp $BUILDDIR/esptool.py $OUTPUTDIR/esp-idf-$IDFVER/components/esptool_py/esptool/esptool.py

cp -r $BUILDDIR/esp-idf/tools  $OUTPUTDIR/esp-idf-$IDFVER/
mv $OUTPUTDIR/esp-idf-$IDFVER/tools/ldgen/ldgen.py  $OUTPUTDIR/esp-idf-$IDFVER/tools/ldgen/ldgen-orig.py
cp $BUILDDIR/ldgen.py $OUTPUTDIR/esp-idf-$IDFVER/tools/ldgen/

for file in CMakeLists.txt Kconfig LICENSE README.md requirements.txt sdkconfig.rename ; do
  cp $BUILDDIR/esp-idf/$file $OUTPUTDIR/esp-idf-$IDFVER/
done

OLDPATH=$PATH
PATH=$BUILDDIR/tmp/xtensa-esp32-elf/bin:$PATH
export PATH

cd $BUILDDIR/esp-idf/examples/get-started/hello_world
cp $BUILDDIR/sdkconfig-idf$IDFVER-esp32.release sdkconfig
make clean 2>&1 | $PV --line-mode --size=105  --name "make clean    " >/dev/null
make -j 8 2>&1  | $PV --line-mode --size=1068 --name "make release  " >/dev/null

find . -path ./build/bootloader -prune -o -name "*.a" -exec cp {} $OUTPUTDIR/lx6/ \;
cp ./build/bootloader/bootloader.bin  $OUTPUTDIR/lx6
cp ./build/partitions_singleapp.bin   $OUTPUTDIR/lx6
cp ./build/esp32/esp32.project.ld     $OUTPUTDIR/lx6
cp ./build/esp32/esp32_out.ld         $OUTPUTDIR/lx6

# Generate OTA partition files
echo Generating partitions_two_ota 
python3 $BUILDDIR/esp-idf/components/partition_table/gen_esp32part.py $BUILDDIR/esp-idf/components/partition_table/partitions_two_ota.csv partitions_two_ota.bin
cp ./partitions_two_ota.bin   $OUTPUTDIR/lx6
# Generate empty ota_data_initial.bin file
echo Generating initial OTA data partition
python3 $BUILDDIR/esp-idf/components/partition_table/gen_empty_partition.py 0x2000 ota_data_initial.bin 
cp ./ota_data_initial.bin   $OUTPUTDIR/lx6

cp $BUILDDIR/sdkconfig-idf$IDFVER-esp32.debug sdkconfig
make clean 2>&1 | $PV --line-mode --size=105  --name "make clean    " >/dev/null
make -j 8 2>&1  | $PV --line-mode --size=1068 --name "make debug    " >/dev/null
mkdir $OUTPUTDIR/lx6/debug
find . -path ./build/bootloader -prune -o -name "*.a" -exec cp {} $OUTPUTDIR/lx6/debug \;
cp ./build/bootloader/bootloader.bin  $OUTPUTDIR/lx6/debug

make clean 2>&1 | $PV --line-mode --size=99 --name "make clean     " >/dev/null

#cleanup
rm -rf $OUTPUTDIR/lx6/include
rm -rf $OUTPUTDIR/lx6/include-fixed
rm -rf $OUTPUTDIR/lx6/install-tools
rm -rf $OUTPUTDIR/lx6/plugin
find $OUTPUTDIR/lx6 -name "*.a" -exec chmod 644 {} \;
find $OUTPUTDIR/lx6 -name "*.o" -exec chmod 644 {} \;

echo
echo "Processing esp8266-rtos"
echo

IDF_PATH=$BUILDDIR/ESP8266_RTOS_SDK
export IDF_PATH

if [ ! -d $BUILDDIR/venv-rtos ]; then
  python3 -m venv $BUILDDIR/venv-rtos
fi

. $BUILDDIR/venv-rtos/bin/activate
python3 -m pip install --upgrade pip 2>/dev/null >/dev/null
python3 -m pip install -r $BUILDDIR/ESP8266_RTOS_SDK/requirements.txt 2>&1 | $PV --line-mode --size=19 --name "install pydeps" >/dev/null

python3 -c 'help("modules")' 2>/dev/null | grep -w cryptography >/dev/null
if [ "$?" != 0 ]; then
  echo "Setting up modules for venv failed, please report back the following lines:"
  python3 -m pip install -r $BUILDDIR/esp-rtos/requirements.txt
  exit 1
fi

mkdir $OUTPUTDIR/lx106

[ -d $BUILDDIR/tmp ] && rm -rf $BUILDDIR/tmp
mkdir $BUILDDIR/tmp
cd $BUILDDIR/tmp
tar zxvf $BUILDDIR/$RTOSGCC 2>&1 | $PV --line-mode --size=1892 --name "extract gcc   " >/dev/null

cp xtensa-lx106-elf/bin/* $OUTPUTDIR/bin/
cp -r xtensa-lx106-elf/libexec $OUTPUTDIR/
cp -r xtensa-lx106-elf/xtensa-lx106-elf/lib/* $OUTPUTDIR/lx106/

#cp $BUILDDIR/ESP8266_RTOS_SDK/components/newlib/newlib/lib/*.a $OUTPUTDIR/lx106/
cp $BUILDDIR/ESP8266_RTOS_SDK/components/esp8266/lib/*.a     $OUTPUTDIR/lx106/
cp $BUILDDIR/ESP8266_RTOS_SDK/components/esp-wolfssl/wolfssl/lib/*.a $OUTPUTDIR/lx106/

mkdir -p $OUTPUTDIR/esp-rtos-$RTOSVER/components
cd $BUILDDIR/ESP8266_RTOS_SDK/components

for pattern in '[kK]config*' '*.lf' '*.info' '*.ld' '*.in' ; do
  find . -type f -name "$pattern" | while read file ; do
    mkdir -p  $OUTPUTDIR/esp-rtos-$RTOSVER/components/$(dirname $file) 2>/dev/null
    cp $file $OUTPUTDIR/esp-rtos-$RTOSVER/components/$file
  done
done

cp -r $BUILDDIR/ESP8266_RTOS_SDK/components/esptool_py  $OUTPUTDIR/esp-rtos-$RTOSVER/components/
mv $OUTPUTDIR/esp-rtos-$RTOSVER/components/esptool_py/esptool/esptool.py $OUTPUTDIR/esp-rtos-$RTOSVER/components/esptool_py/esptool/esptool-orig.py
cp $BUILDDIR/esptool.py $OUTPUTDIR/esp-rtos-$RTOSVER/components/esptool_py/esptool/esptool.py

cp -r $BUILDDIR/ESP8266_RTOS_SDK/tools  $OUTPUTDIR/esp-rtos-$RTOSVER/
mv $OUTPUTDIR/esp-rtos-$RTOSVER/tools/ldgen/ldgen.py  $OUTPUTDIR/esp-rtos-$RTOSVER/tools/ldgen/ldgen-orig.py
cp $BUILDDIR/ldgen.py $OUTPUTDIR/esp-rtos-$RTOSVER/tools/ldgen/

for file in CMakeLists.txt Kconfig LICENSE README.md requirements.txt sdkconfig.rename ; do
  cp $BUILDDIR/ESP8266_RTOS_SDK/$file $OUTPUTDIR/esp-rtos-$RTOSVER/
done

PATH=$BUILDDIR/tmp/xtensa-lx106-elf/bin:$OLDPATH
cd $BUILDDIR/ESP8266_RTOS_SDK/examples/get-started/hello_world
cp $BUILDDIR/sdkconfig-rtos$RTOSVER-lx106.release sdkconfig
make clean 2>&1 | $PV --line-mode --size=65  --name "make clean    " >/dev/null
make -j 8  2>&1 | $PV --line-mode --size=604 --name "make release  " >/dev/null
find . -path ./build/bootloader -prune -o -name "*.a" -exec cp {} $OUTPUTDIR/lx106/ \;
cp ./build/bootloader/bootloader.bin  $OUTPUTDIR/lx106
cp ./build/partitions_singleapp.bin   $OUTPUTDIR/lx106
cp ./build/esp8266/esp8266.project.ld $OUTPUTDIR/lx106
cp ./build/esp8266/esp8266_out.ld     $OUTPUTDIR/lx106

# Generate OTA partition files
echo Generating partitions_two_ota 
python3 $BUILDDIR/ESP8266_RTOS_SDK/components/partition_table/gen_esp32part.py $BUILDDIR/ESP8266_RTOS_SDK/components/partition_table/partitions_two_ota.csv partitions_two_ota.bin
cp ./partitions_two_ota.bin   $OUTPUTDIR/lx106
echo Generating partitions_two_ota 1MB 
python3 $BUILDDIR/ESP8266_RTOS_SDK/components/partition_table/gen_esp32part.py $BUILDDIR/ESP8266_RTOS_SDK/components/partition_table/partitions_two_ota.1MB.csv partitions_two_ota.1MB.bin
cp ./partitions_two_ota.1MB.bin   $OUTPUTDIR/lx106
# Generate empty ota_data_initial.bin file
echo Generating initial OTA data partition
python3 $BUILDDIR/ESP8266_RTOS_SDK/components/partition_table/gen_empty_partition.py 0x2000 ota_data_initial.bin 
cp ./ota_data_initial.bin   $OUTPUTDIR/lx106

cp $BUILDDIR/sdkconfig-rtos$RTOSVER-lx106.debug sdkconfig
make clean 2>&1 | $PV --line-mode --size=64  --name "make clean    " >/dev/null
make -j 8  2>&1 | $PV --line-mode --size=604 --name "make debug    " >/dev/null
mkdir $OUTPUTDIR/lx106/debug
find . -path ./build/bootloader -prune -o -name "*.a" -exec cp {} $OUTPUTDIR/lx106/debug \;
cp ./build/bootloader/bootloader.bin  $OUTPUTDIR/lx106/debug
cp ./build/esp8266/esp8266.project.ld $OUTPUTDIR/lx106/debug
cp ./build/esp8266/esp8266_out.ld     $OUTPUTDIR/lx106/debug

make clean 2>&1 | $PV --line-mode --size=62  --name "make clean    " >/dev/null

#cleanup
find $OUTPUTDIR/lx106 -name "*.a" -exec chmod 644 {} \;
find $OUTPUTDIR/lx106 -name "*.o" -exec chmod 644 {} \;

echo
echo "Zipping Results for $ARCHDIR ..."
cd  $OUTPUTDIR/
rm -f ../esplibs-$ARCHDIR.zip 2>/dev/null
rm -f ../xtensa-binutils-$ARCHDIR.zip 2>/dev/null
zip -r -q ../xtensa-libs-$ARCHDIR.zip lx6 lx106
zip -r -q ../xtensa-binutils-$ARCHDIR.zip bin esp-idf-$IDFVER esp-rtos-$RTOSVER libexec
cd ..

if [ "$ARCHDIR" = "aarch64-darwin" ]; then
  echo "Zipping Results for x86_64-darwin ..."
  mkdir x86_64-darwin
  cp -r aarch64-darwin/* x86_64-darwin/
  cd x86_64-darwin
  zip -r -q ../xtensa-libs-x86_64-darwin.zip lx6 lx106
  zip -r -q ../xtensa-binutils-x86_64-darwin.zip bin esp-idf-$IDFVER esp-rtos-$RTOSVER libexec
  cd ..
  rm -rf x86_64-darwin
fi

if [ "$ARCHDIR" = "x86_64-darwin" ]; then
  echo "Zipping Results for aarch64-darwin ..."
  mkdir aarch64-darwin
  cp -r x86_64-darwin/* aarch64-darwin/
  cd aarch64-darwin
  zip -r -q ../xtensa-libs-aarch64-darwin.zip lx6 lx106
  zip -r -q ../xtensa-binutils-aarch64-darwin.zip bin esp-idf-$IDFVER esp-rtos-$RTOSVER libexec
  cd ..
  rm -rf aarch64-darwin
fi
if [ "$ARCHDIR" = "x86_64-linux" ]; then
  pwd
  echo "Zipping Results for i686-linux ..."
  mkdir i686-linux
  cp -r x86_64-linux/* i686-linux/
  rm -rf i686-linux/bin
  rm -rf i686-linux/libexec
  mkdir -p i686-linux/bin
  mkdir -p i686-linux/libexec

  cd $BUILDDIR/tmp
  tar zxvf $BUILDDIR/$IDFGCCi686_linux 2>&1 | $PV --line-mode --size=2035 --name "extract gcc   " >/dev/null
  cp xtensa-esp32-elf/bin/* $BUILDDIR/i686-linux/bin/
  cp -r xtensa-esp32-elf/libexec $BUILDDIR/i686-linux/

  tar zxvf $BUILDDIR/$RTOSGCCi686_linux 2>&1 | $PV --line-mode --size=1892 --name "extract gcc   " >/dev/null
  cp xtensa-lx106-elf/bin/* $BUILDDIR/i686-linux/bin/
  cp -r xtensa-lx106-elf/libexec $BUILDDIR/i686-linux/
  cd ..

  cd i686-linux
  zip -r -q ../xtensa-libs-i686-linux.zip lx6 lx106
  zip -r -q ../xtensa-binutils-i686-linux.zip bin esp-idf-$IDFVER esp-rtos-$RTOSVER libexec
  cd ..
  rm -rf i686-linux
fi
