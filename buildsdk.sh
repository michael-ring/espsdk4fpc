#!/bin/sh
IDFVER=4.1.1
RTOSVER=3.3
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

IDFGCCi686_linux=xtensa-esp32-elf-gcc8_4_0-esp-2020r3-linux-i686.tar.gz
IDFGCCx86_64_linux=xtensa-esp32-elf-gcc8_4_0-esp-2020r3-linux-amd64.tar.gz
IDFGCCx86_64_darwin=xtensa-esp32-elf-gcc8_4_0-esp-2020r3-macos.tar.gz
IDFGCCaarch64_darwin=xtensa-esp32-elf-gcc8_4_0-esp-2020r3-macos.tar.gz
RTOSGCCi686_linux=xtensa-lx106-elf-linux-1.22.0-100-ge567ec7-5.2.0.tar.gz
RTOSGCCx86_64_linux=xtensa-lx106-elf-linux64-1.22.0-100-ge567ec7-5.2.0.tar.gz
RTOSGCCx86_64_darwin=xtensa-lx106-elf-macos-1.22.0-100-ge567ec7-5.2.0.tar.gz
RTOSGCCaarch64_darwin=xtensa-lx106-elf-macos-1.22.0-100-ge567ec7-5.2.0.tar.gz
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
  sudo apt-get install -y pv python3 python3-pip python3-venv

  [ "$(uname -m)" = "i686" ] && HOSTISLINUXI686=TRUE
  [ "$(uname -m)" = "i686" ] && IDFGCC=$IDFGCCi686_linux
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

echo
echo "Processing esp-idf"
echo
IDF_PATH=$BUILDDIR/esp-idf
export IDF_PATH

if [ ! -d $BUILDDIR/venv-idf ]; then
  python3 -m venv $BUILDDIR/venv-idf
fi
. $BUILDDIR/venv-idf/bin/activate
python3 -m pip install -r $BUILDDIR/esp-idf/requirements.txt 2>&1 | pv --line-mode --size=12 --name "install pydeps" >/dev/null

OUTPUTDIR=$BUILDDIR/$ARCHDIR
[ -d $OUTPUTDIR ] && rm -rf $OUTPUTDIR
mkdir -p $OUTPUTDIR
mkdir $OUTPUTDIR/bin
mkdir $OUTPUTDIR/lx6

[ -d $BUILDDIR/tmp ] && rm -rf $BUILDDIR/tmp
mkdir $BUILDDIR/tmp
cd $BUILDDIR/tmp
tar zxvf $BUILDDIR/$IDFGCC 2>&1 | pv --line-mode --size=1867 --name "extract gcc   " >/dev/null

cp xtensa-esp32-elf/bin/* $OUTPUTDIR/bin/
cp -r xtensa-esp32-elf/libexec $OUTPUTDIR/
cp -r xtensa-esp32-elf/xtensa-esp32-elf/lib/* $OUTPUTDIR/lx6/
cp -r xtensa-esp32-elf/lib/gcc/xtensa-esp32-elf/*/* $OUTPUTDIR/lx6/

cp -r $BUILDDIR/esp-idf/components/xtensa/esp32/   $OUTPUTDIR/lx6/
cp -r $BUILDDIR/esp-idf/components/bt/controller/lib/ $OUTPUTDIR/lx6/
cp -r $BUILDDIR/esp-idf/components/esp_wifi/lib/esp32/ $OUTPUTDIR/lx6/

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
cp $BUILDDIR/sdkconfig-idf4.1-esp32.release sdkconfig
make clean 2>&1 | pv --line-mode --size=85  --name "make clean    " >/dev/null
make -j 8 2>&1  | pv --line-mode --size=937 --name "make release  " >/dev/null

find . -path ./build/bootloader -prune -o -name "*.a" -exec cp {} $OUTPUTDIR/lx6/ \;
cp ./build/bootloader/bootloader.bin  $OUTPUTDIR/lx6
cp ./build/partitions_singleapp.bin   $OUTPUTDIR/lx6
cp $BUILDDIR/sdkconfig-idf4.1-esp32.debug sdkconfig
make clean 2>&1 | pv --line-mode --size=88  --name "make clean    " >/dev/null
make -j 8 2>&1  | pv --line-mode --size=937 --name "make debug    " >/dev/null
mkdir $OUTPUTDIR/lx6/debug
find . -path ./build/bootloader -prune -o -name "*.a" -exec cp {} $OUTPUTDIR/lx6/debug \;
make clean 2>&1 | pv --line-mode --size=86 --name "make clean     " >/dev/null

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
pip3 install -r $BUILDDIR/ESP8266_RTOS_SDK/requirements.txt 2>&1 | pv --line-mode --size=11 --name "install pydeps" >/dev/null

mkdir $OUTPUTDIR/lx106

[ -d $BUILDDIR/tmp ] && rm -rf $BUILDDIR/tmp
mkdir $BUILDDIR/tmp
cd $BUILDDIR/tmp
tar zxvf $BUILDDIR/$RTOSGCC 2>&1 | pv --line-mode --size=1590 --name "extract gcc   " >/dev/null

cp xtensa-lx106-elf/bin/* $OUTPUTDIR/bin/
cp -r xtensa-lx106-elf/libexec $OUTPUTDIR/
cp -r xtensa-lx106-elf/xtensa-lx106-elf/sysroot/lib/* $OUTPUTDIR/lx106/

cp $BUILDDIR/ESP8266_RTOS_SDK/components/newlib/newlib/lib/*.a $OUTPUTDIR/lx106/
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
make clean 2>&1 | pv --line-mode --size=57  --name "make clean    " >/dev/null
make -j 8  2>&1 | pv --line-mode --size=525 --name "make release  " >/dev/null
find . -path ./build/bootloader -prune -o -name "*.a" -exec cp {} $OUTPUTDIR/lx106/ \;
cp ./build/bootloader/bootloader.bin  $OUTPUTDIR/lx106
cp ./build/partitions_singleapp.bin   $OUTPUTDIR/lx106
cp $BUILDDIR/sdkconfig-rtos$RTOSVER-lx106.debug sdkconfig
make clean 2>&1 | pv --line-mode --size=60  --name "make clean    " >/dev/null
make -j 8  2>&1 | pv --line-mode --size=525 --name "make debug    " >/dev/null
mkdir $OUTPUTDIR/lx106/debug
find . -path ./build/bootloader -prune -o -name "*.a" -exec cp {} $OUTPUTDIR/lx106/debug \;
make clean 2>&1 | pv --line-mode --size=59  --name "make clean    " >/dev/null

#cleanup
find $OUTPUTDIR/lx106 -name "*.a" -exec chmod 644 {} \;
find $OUTPUTDIR/lx106 -name "*.o" -exec chmod 644 {} \;

echo
echo "Zipping Results..."
cd  $OUTPUTDIR/
rm -f ../esplibs-$ARCHDIR.zip 2>/dev/null
rm -f ../xtensa-binutils-$ARCHDIR.zip 2>/dev/null
zip -r -q ../esplibs-$ARCHDIR.zip lx6 lx106
zip -r -q ../xtensa-binutils-$ARCHDIR.zip bin esp-idf-$IDFVER esp-rtos-$RTOSVER libexec

