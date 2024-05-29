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
pip3 -h 2>/dev/null >/dev/null
if [ "$?" != 0 ]; then
  echo "python3 module 'pip3' is not installed, please fix"
  echo "on debian like linux: sudo apt-get install python3-pip"
  echo "on redhat like linux: sudo dnf install python3-pip"
  exit 1
fi
python3 -m venv -h 2>/dev/null >/dev/null
if [ "$?" != 0 ]; then
  echo "python3 module 'venv' is not installed, please fix"
  echo "on debian like linux: sudo apt-get install python3-venv"
  echo "on redhat like linux: sudo dnf install python3-venv"
  exit 1
fi

python3 -m virtualenv -h 2>/dev/null >/dev/null
if [ "$?" != 0 ]; then
  echo "python3 module 'virtualenv' is not installed, please fix"
  echo "on debian like linux: sudo apt-get install python3-virtualenv"
  echo "on redhat like linux: sudo dnf install python3-virtualenv"
  exit 1
fi

python3 -m wheel -h 2>/dev/null >/dev/null
if [ "$?" != 0 ]; then
  echo "python3 module 'wheel' is not installed, please fix"
  echo "on debian like linux: sudo apt-get install python3-wheel"
  echo "on redhat like linux: sudo dnf install python3-wheel"
  exit 1
fi

BUILDDIR="$(pwd)"

#for sdk in 4.4.7 5.0.6 5.2.1 ; do
for sdk in 5.2.1; do
  cd "$BUILDDIR" 
  #rm -rf "$BUILDDIR/esp-idf" 2>/dev/null
  #git clone -b "v$sdk" --recursive https://github.com/espressif/esp-idf.git 2>&1 | pv --line-mode --size=85 --name "clone esp-idf $sdk " >/dev/null
  cd esp-idf
  IDF_TOOLS_PATH="$BUILDDIR/tools-$sdk"
  IDF_LIBS_PATH="$BUILDDIR/esp-idf-$sdk/"
  rm -rf "$IDF_TOOLS_PATH" 2>/dev/null
  rm -rf "$IDF_LIBS_PATH" 2>/dev/null
  mkdir -p "$IDF_TOOLS_PATH"
  mkdir -p "$IDF_LIBS_PATH"
  export "IDF_TOOLS_PATH"
  if [ $sdk = 4.4.7 ]; then
    TARGETS=(esp32 esp32s2 esp32c3 esp32s3)
    ./install.sh esp32,esp32s2,esp32c3,esp32s3 >/dev/null
  fi
  if [ $sdk = 5.0.6 ]; then
    TARGETS=(esp32 esp32s2 esp32c3 esp32s3 esp32c2)
    ./install.sh esp32,esp32s2,esp32c3,esp32s3,esp32c2 >/dev/null
  fi
  if [ $sdk = 5.2.1 ]; then
    TARGETS=(esp32 esp32s2 esp32s3 esp32c2 esp32c3 esp32c6)
    ./install.sh esp32,esp32s2,esp32s3,esp32c2,esp32c3,esp32c6 >/dev/null
  fi

  . ./export.sh >/dev/null
  
  for target in $TARGETS ; do
    TARGETDIR="libs/lx6/$target"
    echo "$target" | grep "esp32s2" >/dev/null && TARGETDIR="libs/lx7/$target"
    echo "$target" | grep "esp32s3" >/dev/null && TARGETDIR="libs/lx7/$target"
    echo "$target" | grep "esp32c2" >/dev/null && TARGETDIR="libs/rv32imc/$target" && subarch="rv32imc"
    echo "$target" | grep "esp32c3" >/dev/null && TARGETDIR="libs/rv32imc/$target" && subarch="rv32imc"
    echo "$target" | grep "esp32c6" >/dev/null && TARGETDIR="libs/rv32imac/$target" && subarch="rv32imac"
    mkdir -p "$IDF_LIBS_PATH/$TARGETDIR/release"
    mkdir -p "$IDF_LIBS_PATH/$TARGETDIR/debug"

    cd "$BUILDDIR/esp-idf/components"

    find . -name "*.a" | grep "/$target/" | while read file ; do
      cp $file "$IDF_LIBS_PATH/$TARGETDIR/"
      cp $file "$IDF_LIBS_PATH/$TARGETDIR/"
    done

    if [ "$target" = "esp32c2" -o "$target" = "esp32c3" -o "$target" = "esp32c6"  -o "$target" = "esp32h2" ]; then
      cd $IDF_TOOLS_PATH/tools/riscv32-esp-elf/*/*/lib/gcc/riscv32-esp-elf/*/$subarch*
      for pattern in '*.a' '*.o' ; do
        find . -type f -name "$pattern" | while read file ; do
          mkdir -p  "$IDF_LIBS_PATH/$TARGETDIR/$(dirname $file)" 2>/dev/null
          cp $file "$IDF_LIBS_PATH/$TARGETDIR/$file"
        done
      done

      cd $IDF_TOOLS_PATH/tools/riscv32-esp-elf/*/*/*/lib/$subarch*
      for pattern in '*.a' '*.o' ; do
        find . -type f -name "$pattern" | while read file ; do
          mkdir -p  "$IDF_LIBS_PATH/$TARGETDIR/$(dirname $file)" 2>/dev/null
          cp $file "$IDF_LIBS_PATH/$TARGETDIR/$file"
        done
      done
    else
      if [ $sdk = 5.2.1 ]; then
        cd $IDF_TOOLS_PATH/tools/xtensa-esp-elf/*/*/lib/gcc/*/*/$target
      else
        cd $IDF_TOOLS_PATH/tools/*$target-elf/*/*/lib/gcc/*/*/
      fi
      for pattern in '*.a' '*.o' ; do
        find . -type f -name "$pattern" | while read file ; do
          mkdir -p  "$IDF_LIBS_PATH/$TARGETDIR/$(dirname $file)" 2>/dev/null
          cp $file "$IDF_LIBS_PATH/$TARGETDIR/$file"
        done
      done

      if [ $sdk = 5.2.1 ]; then
        cd $IDF_TOOLS_PATH/tools/xtensa-esp-elf/*/*/*/lib/$target
      else
        cd $IDF_TOOLS_PATH/tools/*$target-elf/*/*/*/lib/
      fi
      for pattern in '*.a' '*.o' ; do
        find . -type f -name "$pattern" | while read file ; do
          mkdir -p  "$IDF_LIBS_PATH/$TARGETDIR/$(dirname $file)" 2>/dev/null
          cp $file "$IDF_LIBS_PATH/$TARGETDIR/$file"
        done
      done
    fi

    cd "$BUILDDIR/esp-idf/examples/get-started/hello_world"
    rm -rf build 2>/dev/null
    rm sdkconfig 2>/dev/null
    idf.py set-target $target >/dev/null

    [ -f "$BUILDDIR/sdkconfig-idf$sdk-$target.release" ] && cp "$BUILDDIR/sdkconfig-idf$sdk-$target.release" sdkconfig
    idf.py build | pv --line-mode --size=1200 --name "build  $target for esp-idf $sdk " >/dev/null

    mkdir -p "$IDF_LIBS_PATH/$TARGETDIR/release/"
    mkdir -p "$IDF_LIBS_PATH/$TARGETDIR/debug/"

    find . -path ./build/esp-idf -prune -o -name "*.a" -exec cp {} "$IDF_LIBS_PATH/$TARGETDIR/release/" \;
    find . -path ./build/bootloader -prune -o -name "*.a" -exec cp {} "$IDF_LIBS_PATH/$TARGETDIR/release/" \;

    [ ! -f "$BUILDDIR/sdkconfig-idf$sdk-$target.release" ] && cp sdkconfig "$BUILDDIR/sdkconfig-idf$sdk-$target.release"

    [ -f "$BUILDDIR/sdkconfig-idf$sdk-$target.debug" ] && cp "$BUILDDIR/sdkconfig-idf$sdk-$target.release" sdkconfig
    idf.py build | pv --line-mode --size=1200 --name "build  $target for esp-idf $sdk " >/dev/null

    find . -path ./build/esp-idf -prune -o -name "*.a" -exec cp {} "$IDF_LIBS_PATH/$TARGETDIR/debug/" \;
    find . -path ./build/bootloader -prune -o -name "*.a" -exec cp {} "$IDF_LIBS_PATH/$TARGETDIR/debug/" \;

    cp ./build/bootloader/bootloader.bin  "$IDF_LIBS_PATH/$TARGETDIR"
    cp ./build/partition_table/partition-table.bin "$IDF_LIBS_PATH/$TARGETDIR"
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

    for arch in aarch64-darwin x86_64-darwin x86_64-linux i686-linux ; do
      mkdir -p "$BUILDDIR/$arch/"
      cp -r "$BUILDDIR/esp-idf-$sdk" "$BUILDDIR/$arch/"
    done
    rm -rf "$BUILDDIR/esp-idf-$sdk" 2>/dev/null
  done
  
  cd "$BUILDDIR/esp-idf/tools"
  if [ $sdk = 5.2.1 ]; then
    #python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c2,esp32c3,esp32c6 --platform macos-arm64 xtensa-esp32-elf xtensa-esp32s2-elf xtensa-esp32s3-elf riscv32-esp-elf #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
    #python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c2,esp32c3,esp32c6 --platform macos       xtensa-esp32-elf xtensa-esp32s2-elf xtensa-esp32s3-elf riscv32-esp-elf #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
    #python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c2,esp32c3,esp32c6 --platform linux-amd64 xtensa-esp32-elf xtensa-esp32s2-elf xtensa-esp32s3-elf riscv32-esp-elf #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
    #python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c2,esp32c3,esp32c6 --platform linux-i686  xtensa-esp32-elf xtensa-esp32s2-elf xtensa-esp32s3-elf riscv32-esp-elf #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
    python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c2,esp32c3,esp32c6 --platform macos-arm64 xtensa-esp-elf riscv32-esp-elf #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
    python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c2,esp32c3,esp32c6 --platform macos       xtensa-esp-elf riscv32-esp-elf #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
    python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c2,esp32c3,esp32c6 --platform linux-amd64 xtensa-esp-elf riscv32-esp-elf #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
    python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c2,esp32c3,esp32c6 --platform linux-i686  xtensa-esp-elf riscv32-esp-elf #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
  else
    python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c2,esp32c3 --platform macos-arm64 xtensa-esp32-elf xtensa-esp32s2-elf xtensa-esp32s3-elf riscv32-esp-elf #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
    python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c2,esp32c3 --platform macos       xtensa-esp32-elf xtensa-esp32s2-elf xtensa-esp32s3-elf riscv32-esp-elf #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
    python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c2,esp32c3 --platform linux-amd64 xtensa-esp32-elf xtensa-esp32s2-elf xtensa-esp32s3-elf riscv32-esp-elf #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
    python3 idf_tools.py download --targets esp32,esp32s2,esp32s3,esp32c2,esp32c3 --platform linux-i686  xtensa-esp32-elf xtensa-esp32s2-elf xtensa-esp32s3-elf riscv32-esp-elf #| pv --line-mode --size=10 --name "download binutils for esp-idf $sdk " >/dev/null
  fi
  rm $IDF_TOOLS_PATH/dist/*-gdb-* >/dev/null 2>&1
  for target arch arch2 in \
      esp     aarch64-darwin aarch64-apple-darwin \
      esp     x86_64-darwin  x86_64-apple-darwin \
      esp     x86_64-linux   x86_64-linux-gnu \
      esp     i686-linux     i586-linux-gnu \
      esp32   aarch64-darwin macos-arm64 \
      esp32   x86_64-darwin  macos \
      esp32   x86_64-linux   linux-amd64 \
      esp32   i686-linux     linux-i686 \
      esp32s2 aarch64-darwin macos-arm64 \
      esp32s2 x86_64-darwin  macos \
      esp32s2 x86_64-linux   linux-amd64 \
      esp32s2 i686-linux     linux-i686 \
      esp32s3 aarch64-darwin macos-arm64 \
      esp32s3 x86_64-darwin  macos \
      esp32s3 x86_64-linux   linux-amd64 \
      esp32s3 i686-linux     linux-i686
  do
    BINTARGETDIR="$BUILDDIR/$arch/esp-idf-$sdk"

    if [ $sdk = 5.2.1 ]; then
      SOURCE="$(ls $IDF_TOOLS_PATH/dist/xtensa-esp-elf-*-$arch2.tar.?z)" >/dev/null 2>&1
    else
      SOURCE="$(ls $IDF_TOOLS_PATH/dist/xtensa-$target-elf-gcc*-$arch2.tar.?z)"  >/dev/null 2>&1
    fi
    if [ -s "$SOURCE" ]; then
      echo $SOURCE
      mkdir -p "$BINTARGETDIR/tmp"
      cd "$BINTARGETDIR/tmp"
      tar zxvf "$SOURCE" >/dev/null 2>&1
      [ "$?" != 0 ] && xzcat "$SOURCE" | tar xvf - >/dev/null 2>&1
      cd ..
      mkdir bin 2>/dev/null
      mv tmp/*/bin/*as bin/
      mv tmp/*/bin/*ld bin/
      mv tmp/*/bin/*objdump bin/
      mv tmp/*/bin/*objcopy bin/
      rm -rf tmp

      mkdir -p $BINTARGETDIR/tools/ 
      cp -r $BUILDDIR/esp-idf/tools $BINTARGETDIR/

      cd "$BUILDDIR/esp-idf/components"
      for pattern in '[kK]config*' '*.lf' '*.info' '*.ld' '*.in' ; do
        find . -type f -name "$pattern" | while read file ; do
          mkdir -p  "$BINTARGETDIR/components/$(dirname $file)" 2>/dev/null
          cp $file "$BINTARGETDIR/components/$file"
        done
      done
      cp -r esptool_py  "$BINTARGETDIR/components/"
      cp "$BUILDDIR/esptool.py" "$BINTARGETDIR/components/esptool_py/esptool/esptool.py"

      for file in CMakeLists.txt Kconfig LICENSE README.md sdkconfig.rename ; do
        cp "$BUILDDIR/esp-idf/$file" "$BINTARGETDIR/"
      done
    fi
  done

  for target arch arch2 in \
      esp     aarch64-darwin aarch64-apple-darwin \
      esp     x86_64-darwin  x86_64-apple-darwin \
      esp     x86_64-linux   x86_64-linux-gnu \
      esp     i686-linux     i586-linux-gnu \
      esp32c2 aarch64-darwin macos-arm64 \
      esp32c2 x86_64-darwin  macos \
      esp32c2 x86_64-linux   linux-amd64 \
      esp32c2 i686-linux     linux-i686 \
      esp32c3 aarch64-darwin macos-arm64 \
      esp32c3 x86_64-darwin  macos \
      esp32c3 x86_64-linux   linux-amd64 \
      esp32c3 i686-linux     linux-i686 \
      esp32c6 aarch64-darwin macos-arm64 \
      esp32c6 x86_64-darwin  macos \
      esp32c6 x86_64-linux   linux-amd64 \
      esp32c6 i686-linux     linux-i686
  do
    BINTARGETDIR="$BUILDDIR/$arch/esp-idf-$sdk"
    if [ $sdk = 5.2.1 ]; then
      SOURCE="$(ls $IDF_TOOLS_PATH/dist/riscv32-esp-elf-*-$arch2.tar.?z )"  >/dev/null 2>&1
    else
      SOURCE="$(ls $IDF_TOOLS_PATH/dist/riscv32-esp-elf-gcc*-$arch2.tar.?z )"  >/dev/null 2>&1
    fi
    if [ -s "$SOURCE" ]; then
      echo $SOURCE
      mkdir -p "$BINTARGETDIR/tmp"
      cd "$BINTARGETDIR/tmp"
      tar zxvf "$SOURCE" >/dev/null 2>&1
      [ "$?" != 0 ] && xzcat "$SOURCE" | tar xvf - >/dev/null 2>&1
      cd ..
      mkdir bin 2>/dev/null
      mv tmp/*/bin/*as bin/
      mv tmp/*/bin/*ld bin/
      mv tmp/*/bin/*objdump bin/
      mv tmp/*/bin/*objcopy bin/
      rm -rf tmp 

      mkdir -p $BINTARGETDIR/tools/ 
      cp -r $BUILDDIR/esp-idf/tools $BINTARGETDIR/

      cd "$BUILDDIR/esp-idf/components"
      for pattern in '[kK]config*' '*.lf' '*.info' '*.ld' '*.in' ; do
        find . -type f -name "$pattern" | while read file ; do
          mkdir -p  "$BINTARGETDIR/components/$(dirname $file)" 2>/dev/null
          cp $file "$BINTARGETDIR/components/$file"
        done
      done
      cp -r esptool_py  "$BINTARGETDIR/components/"
      cp "$BUILDDIR/esptool.py" "$BINTARGETDIR/components/esptool_py/esptool/esptool.py"

      for file in CMakeLists.txt Kconfig LICENSE README.md sdkconfig.rename ; do
        cp "$BUILDDIR/esp-idf/$file" "$BINTARGETDIR/" 2>/dev/null
      done
    fi
  done
  #rm -rf $BUILDDIR/esp-idf 2>/dev/null
  #rm -rf $BUILDDIR/tools-$sdk 2>/dev/null
done
