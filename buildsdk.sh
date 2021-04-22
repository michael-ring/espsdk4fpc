#!/bin/sh
git submodule update --init --recursive

HOSTISWINDOWS=
HOSTISLINUX=
HOSTISDARWIN=
HOSTISDARWINX86_64=
HOSTISDARWINARM64=
HOSTISLINUXX86_64=
HOSTISLINUXI686=

IDFGCCx86_64_linux=xtensa-esp32-elf-gcc8_4_0-esp-2020r3-linux64-amd64.tar.gz
IDFGCCx86_64_darwin=xtensa-esp32-elf-gcc8_4_0-esp-2020r3-macos.tar.gz
IDFGCCaarch64_darwin=xtensa-esp32-elf-gcc8_4_0-esp-2020r3-macos.tar.gz
IDFGCC=

BUILDDIR=$(pwd)
if [ "$(uname -s)" = "Darwin" ]; then
  HOSTISDARWIN=TRUE
  [ "$(uname -m)" = "x86_64" ] && HOSTISDARWINX86_64=TRUE
  [ "$(uname -m)" = "x86_64" ] && ARCHDIR=x86_64-darwin
  [ "$(uname -m)" = "x86_64" ] && IDFGCC=$IDFGCCx86_64_darwin

  [ "$(uname -m)" = "arm64" ]  && HOSTISDARWINARM64=TRUE
  [ "$(uname -m)" = "arm64" ]  && ARCHDIR=aarch64-darwin
  [ "$(uname -m)" = "arm64" ]  && IDFGCC=$IDFGCCx86_64_darwin
fi

if [ "$(uname -s)" = "Linux" -a "$CC" != "/usr/src/mxe/usr/bin/x86_64-w64-mingw32.static-gcc" ]; then
  HOSTISLINUX=TRUE
  [ "$(uname -m)" = "x86_64" ] && HOSTISLINUXX86_64=TRUE
  [ "$(uname -m)" = "x86_64" ] && IDFGCC=$IDFGCCx86_64_linux
  [ "$(uname -m)" = "i686"   ] && HOSTISLINUXI686=TRUE
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

OUTPUTDIR=$BUILDDIR/$ARCHDIR
[ -d $OUTPUTDIR ] && rm -rf $OUTPUTDIR
mkdir -p $OUTPUTDIR
mkdir $OUTPUTDIR/bin
mkdir $OUTPUTDIR/lib

[ -d $BUILDDIR/tmp ] && rm -rf $BUILDDIR/tmp
mkdir $BUILDDIR/tmp
cd $BUILDDIR/tmp
tar zxf $BUILDDIR/$IDFGCC
cp xtensa-esp32-elf/bin/* $OUTPUTDIR/bin/
cp -r xtensa-esp32-elf/libexec $OUTPUTDIR/
cp -r xtensa-esp32-elf/xtensa-esp32-elf/lib/* $OUTPUTDIR/lib/
cp -r xtensa-esp32-elf/lib/gcc/xtensa-esp32-elf/*/* $OUTPUTDIR/lib/
rm -rf $OUTPUTDIR/lib/include
rm -rf $OUTPUTDIR/lib/include-fixed
rm -rf $OUTPUTDIR/lib/install-tools
rm -rf $OUTPUTDIR/lib/plugin

cp -r $BUILDDIR/esp-idf/components/xtensa/esp32   $OUTPUTDIR/lib/
cp -r $BUILDDIR/esp-idf/components/xtensa/esp32s3 $OUTPUTDIR/lib/ 
cp -r $BUILDDIR/esp-idf/components/xtensa/esp32s2 $OUTPUTDIR/lib/
cp -r $BUILDDIR/esp-idf/components/bt/controller/lib/esp32c3 $OUTPUTDIR/lib/
cp -r $BUILDDIR/esp-idf/components/bt/controller/lib/esp32 $OUTPUTDIR/lib/
cp -r $BUILDDIR/esp-idf/components/bt/controller/lib/esp32s3 $OUTPUTDIR/lib/
cp -r $BUILDDIR/esp-idf/components/esp_wifi/lib/esp32c3 $OUTPUTDIR/lib/
cp -r $BUILDDIR/esp-idf/components/esp_wifi/lib/esp32 $OUTPUTDIR/lib/
cp -r $BUILDDIR/esp-idf/components/esp_wifi/lib/esp32s3 $OUTPUTDIR/lib/
cp -r $BUILDDIR/esp-idf/components/esp_wifi/lib/esp32s2 $OUTPUTDIR/lib/

PATH=$BUILDDIR/tmp/xtensa-esp32-elf/bin:$PATH
cd $BUILDDIR/esp-idf/examples/get-started/hello_world
cp $BUILDDIR/sdkconfig-idf4.1-esp32.release sdkconfig
make clean #2>/dev/null | pv -p -s 100 --name make clean
make #2>/dev/null | pv -p -s 100 --name make
find . -path ./build/bootloader -prune -o -name "*.a" -exec cp {} $OUTPUTDIR/lib/ \;
cp $BUILDDIR/sdkconfig-idf4.1-esp32.debug sdkconfig
make clean #2>/dev/null | pv -p -s 100 --name make clean
make #2>/dev/null | pv -p -s 100 --name make
mkdir $OUTPUTDIR/lib/debug
find . -path ./build/bootloader -prune -o -name "*.a" -exec cp {} $OUTPUTDIR/lib/debug \;
make clean #2>/dev/null | pv -p -s 100 --name make clean