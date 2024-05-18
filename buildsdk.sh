#!/bin/zsh

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

BUILDDIR="$(pwd)"

#for sdk in 4.4.7 5.0.6 5.2.1 ; do
#for sdk in 4.4.7 5.0.6; do
for sdk in 4.4.7 5.0.6 ; do
  cd "$BUILDDIR" 
  rm -rf "$BUILDDIR/esp-idf" 2>/dev/null
  git clone -b "v$sdk" --recursive https://github.com/espressif/esp-idf.git 2>&1 | pv --line-mode --size=85 --name "clone esp-idf $sdk " >/dev/null
  cd esp-idf
  IDF_TOOLS_PATH="$BUILDDIR/tools-$sdk"
  IDF_LIBS_PATH="$BUILDDIR/$sdk/"
  rm -rf "$IDF_TOOLS_PATH" 2>/dev/null
  rm -rf "$IDF_LIBS_PATH" 2>/dev/null
  mkdir -p "$IDF_TOOLS_PATH"
  mkdir -p "$IDF_LIBS_PATH"
  export "IDF_TOOLS_PATH"
  TARGETS=(esp32 esp32s2 esp32s3 esp32c3 esp32c6)
  ./install.sh esp32,esp32s2,esp32s3,esp32c3,esp32c6 >/dev/null
  if [ "$?" != "0" ]; then
    TARGETS=(esp32 esp32s2 esp32s3 esp32c3)
    ./install.sh esp32,esp32s2,esp32s3,esp32c3 >/dev/null
  fi

  . ./export.sh >/dev/null
  
  for target in $TARGETS ; do
    TARGETDIR="$target/xtensa-libs/lx6"
    echo "$target" | grep "esp32c" >/dev/null && TARGETDIR="$target/riscv32-libs/riscv32"
    mkdir -p "$IDF_LIBS_PATH/$TARGETDIR/release"
    mkdir -p "$IDF_LIBS_PATH/$TARGETDIR/debug"

    cd "$BUILDDIR/esp-idf/components"

    find . -name "*.a" | grep "/$target/" | while read file ; do
      cp $file "$IDF_LIBS_PATH/$TARGETDIR/release/"
      cp $file "$IDF_LIBS_PATH/$TARGETDIR/debug/"
    done

    TARGET2=$(echo $target | sed "s,c.,,g")
    cd $IDF_TOOLS_PATH/tools/*$TARGET2-elf/*/*/lib/gcc/*/*/
    pwd
    for pattern in '*.a' '*.o' ; do
      find . -type f -name "$pattern" | while read file ; do
        mkdir -p  "$IDF_LIBS_PATH/$TARGETDIR/release/$(dirname $file)" 2>/dev/null
        cp $file "$IDF_LIBS_PATH/$TARGETDIR/release/$file"
        mkdir -p  "$IDF_LIBS_PATH/$TARGETDIR/debug/$(dirname $file)" 2>/dev/null
        cp $file "$IDF_LIBS_PATH/$TARGETDIR/debug/$file"
      done
    done

    cd "$BUILDDIR/esp-idf/examples/get-started/hello_world"
    rm -rf build 2>/dev/null
    rm sdkconfig 2>/dev/null
    idf.py set-target $target >/dev/null

    [ -f "$BUILDDIR/sdkconfig-idf$sdk-$target.release" ] && cp "$BUILDDIR/sdkconfig-idf$sdk-$target.release" sdkconfig
    idf.py build | pv --line-mode --size=1200 --name "build  $target for esp-idf $sdk " >/dev/null

    find . -path ./build/bootloader -prune -o -name "*.a" -exec cp {} "$IDF_LIBS_PATH/$TARGETDIR/release/" \;
    find . -path ./build/esp-idf -prune -o -name "*.a" -exec cp {} "$IDF_LIBS_PATH/$TARGETDIR/release/" \;

    [ ! -f "$BUILDDIR/sdkconfig-idf$sdk-$target.release" ] && cp sdkconfig "$BUILDDIR/sdkconfig-idf$sdk-$target.release"

    [ -f "$BUILDDIR/sdkconfig-idf$sdk-$target.debug" ] && cp "$BUILDDIR/sdkconfig-idf$sdk-$target.release" sdkconfig
    idf.py build | pv --line-mode --size=1200 --name "build  $target for esp-idf $sdk " >/dev/null

    find . -path ./build/bootloader -prune -o -name "*.a" -exec cp {} "$IDF_LIBS_PATH/$TARGETDIR/debug/" \;
    find . -path ./build/esp-idf -prune -o -name "*.a" -exec cp {} "$IDF_LIBS_PATH/$TARGETDIR/debug/" \;

    cp ./build/bootloader/bootloader.bin  "$IDF_LIBS_PATH/$TARGETDIR"
    cp ./build/partition_table/partition-table.bin "$IDF_LIBS_PATH/$TARGETDIR"
    #cp ./build/partitions_singleapp.bin   "$IDF_LIBS_PATH/$TARGETDIR"
    cp ./build/esp-idf/esp_system/ld/memory.ld    "$IDF_LIBS_PATH/$TARGETDIR"
    cp ./build/esp-idf/esp_system/ld/sections.ld  "$IDF_LIBS_PATH/$TARGETDIR"

    # Generate OTA partition files
    echo Generating partitions_two_ota 
    python3 "$BUILDDIR/esp-idf/components/partition_table/gen_esp32part.py" "$BUILDDIR/esp-idf/components/partition_table/partitions_two_ota.csv" build/partitions_two_ota.bin
    cp ./build/partitions_two_ota.bin "$IDF_LIBS_PATH/$TARGETDIR"
    # Generate empty ota_data_initial.bin file
    echo Generating initial OTA data partition
    python3 "$BUILDDIR/esp-idf/components/partition_table/gen_empty_partition.py" 0x2000 build/ota_data_initial.bin 
    cp ./build/ota_data_initial.bin   "$IDF_LIBS_PATH/$TARGETDIR"
  done

  cd "$BUILDDIR/esp-idf/tools"
  python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c3,esp32s6 --platform macos-arm64 #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
  [ "$?" != 0 ] && python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c3 --platform macos-arm64 #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
  python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c3,esp32c6 --platform macos #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
  [ "$?" != 0 ] && python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c3 --platform macos #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
  python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c3,esp32c6 --platform linux-arm64 #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
  [ "$?" != 0 ] && python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c3 --platform linux-arm64  #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
  python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c3,esp32c6 --platform linux-i686 #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
  [ "$?" != 0 ] && python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c3 --platform linux-i686 #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null

  for target arch arch2 in \
      esp32   aarch64-darwin macos-arm64 \
      esp32   x86_64-darwin  macos \
      esp32   amd64-linux    linux-arm64 \
      esp32   i686-linux     linux-i686 \
      esp32s2 aarch64-darwin macos-arm64 \
      esp32s2 x86_64-darwin  macos \
      esp32s2 amd64-linux    linux-arm64 \
      esp32s2 i686-linux     linux-i686 \
      esp32s3 aarch64-darwin macos-arm64 \
      esp32s3 x86_64-darwin  macos \
      esp32s3 amd64-linux    linux-arm64 \
      esp32s3 i686-linux     linux-i686
  do
    SOURCE="$(ls $IDF_TOOLS_PATH/dist/xtensa-$target-elf-gcc*-$arch2.tar.?z)"
    echo $SOURCE
    if [ -s "$SOURCE" ]; then
      mkdir -p "$BUILDDIR/$sdk/$target/xtensa-binutils-$arch/tmp"
      cd "$BUILDDIR/$sdk/$target/xtensa-binutils-$arch/tmp"
      tar zxvf "$SOURCE" >/dev/null 2>&1
      [ "$?" != 0 ] && xzcat "$SOURCE" | tar xvf - >/dev/null 2>&1
      cd ..
      mv tmp/*/bin .
      mv tmp/*/libexec .
      rm -rf tmp

      mkdir -p $BUILDDIR/$sdk/$target/xtensa-binutils-$arch/esp-idf-$sdk/tools/ 
      cp -r $BUILDDIR/esp-idf/tools $BUILDDIR/$sdk/$target/xtensa-binutils-$arch/esp-idf-$sdk/

      cd "$BUILDDIR/esp-idf/components"
      for pattern in '[kK]config*' '*.lf' '*.info' '*.ld' '*.in' ; do
        find . -type f -name "$pattern" | while read file ; do
          mkdir -p  "$BUILDDIR/$sdk/$target/xtensa-binutils-$arch/esp-idf-$sdk/components/$(dirname $file)" 2>/dev/null
          cp $file "$BUILDDIR/$sdk/$target/xtensa-binutils-$arch/esp-idf-$sdk/components/$file"
        done
      done
      cp -r esptool_py  "$BUILDDIR/$sdk/$target/xtensa-binutils-$arch/esp-idf-$sdk/components/"
      mv "$BUILDDIR/$sdk/$target/xtensa-binutils-$arch/esp-idf-$sdk/components/esptool_py/esptool/esptool.py" "$BUILDDIR/$sdk/$target/xtensa-binutils-$arch/esp-idf-$sdk/components/esptool_py/esptool/esptool-orig.py"
      cp "$BUILDDIR/esptool.py" "$BUILDDIR/$sdk/$target/xtensa-binutils-$arch/esp-idf-$sdk/components/esptool_py/esptool/esptool.py"

      mv "$BUILDDIR/$sdk/$target/xtensa-binutils-$arch/esp-idf-$sdk/tools/ldgen/ldgen.py"  "$BUILDDIR/$sdk/$target/xtensa-binutils-$arch/esp-idf-$sdk/tools/ldgen/ldgen-orig.py"
      cp "$BUILDDIR/ldgen.py" "$BUILDDIR/$sdk/$target/xtensa-binutils-$arch/esp-idf-$sdk/tools/ldgen/"

      for file in CMakeLists.txt Kconfig LICENSE README.md requirements.txt sdkconfig.rename ; do
        cp "$BUILDDIR/esp-idf/$file" "$BUILDDIR/$sdk/$target/xtensa-binutils-$arch/esp-idf-$sdk/" 2>/dev/null
      done
    fi
  done

  for target arch arch2 in \
      esp32c3 aarch64-darwin macos-arm64 \
      esp32c3 x86_64-darwin  macos \
      esp32c3 amd64-linux    linux-arm64 \
      esp32c3 i686-linux     linux-i686 \
      esp32c6 aarch64-darwin macos-arm64 \
      esp32c6 x86_64-darwin  macos \
      esp32c6 amd64-linux    linux-arm64 \
      esp32c6 i686-linux     linux-i686
  do
    SOURCE="$(ls $IDF_TOOLS_PATH/dist/riscv32-esp-elf-gcc*-$arch2.tar.?z)"
    echo $SOURCE
    if [ -s "$SOURCE" ]; then
      mkdir -p "$BUILDDIR/$sdk/$target/riscv32-binutils-$arch/tmp"
      cd "$BUILDDIR/$sdk/$target/riscv32-binutils-$arch/tmp"
      tar zxvf "$SOURCE" >/dev/null 2>&1
      [ "$?" != 0 ] && xzcat "$SOURCE" | tar xvf - >/dev/null 2>&1
      cd ..
      mv tmp/*/bin .
      mv tmp/*/libexec .
      rm -rf tmp 

      mkdir -p $BUILDDIR/$sdk/$target/riscv32-binutils-$arch/esp-idf-$sdk/tools/ 
      cp -r $BUILDDIR/esp-idf/tools $BUILDDIR/$sdk/$target/riscv32-binutils-$arch/esp-idf-$sdk/

      cd "$BUILDDIR/esp-idf/components"
      for pattern in '[kK]config*' '*.lf' '*.info' '*.ld' '*.in' ; do
        find . -type f -name "$pattern" | while read file ; do
          mkdir -p  "$BUILDDIR/$sdk/$target/riscv32-binutils-$arch/esp-idf-$sdk/components/$(dirname $file)" 2>/dev/null
          cp $file "$BUILDDIR/$sdk/$target/riscv32-binutils-$arch/esp-idf-$sdk/components/$file"
        done
      done
      cp -r esptool_py  "$BUILDDIR/$sdk/$target/riscv32-binutils-$arch/esp-idf-$sdk/components/"
      mv "$BUILDDIR/$sdk/$target/riscv32-binutils-$arch/esp-idf-$sdk/components/esptool_py/esptool/esptool.py" "$BUILDDIR/$sdk/$target/riscv32-binutils-$arch/esp-idf-$sdk/components/esptool_py/esptool/esptool-orig.py"
      cp "$BUILDDIR/esptool.py" "$BUILDDIR/$sdk/$target/riscv32-binutils-$arch/esp-idf-$sdk/components/esptool_py/esptool/esptool.py"

      mv "$BUILDDIR/$sdk/$target/riscv32-binutils-$arch/esp-idf-$sdk/tools/ldgen/ldgen.py"  "$BUILDDIR/$sdk/$target/riscv32-binutils-$arch/esp-idf-$sdk/tools/ldgen/ldgen-orig.py"
      cp "$BUILDDIR/ldgen.py" "$BUILDDIR/$sdk/$target/riscv32-binutils-$arch/esp-idf-$sdk/tools/ldgen/"

      for file in CMakeLists.txt Kconfig LICENSE README.md requirements.txt sdkconfig.rename ; do
        cp "$BUILDDIR/esp-idf/$file" "$BUILDDIR/$sdk/$target/riscv32-binutils-$arch/esp-idf-$sdk/" 2>/dev/null
      done
    fi
  done
  rm -rf $BUILDDIR/esp-idf 2>/dev/null
  rm -rf $BUILDDIR/tools-$sdk 2>/dev/null

done
