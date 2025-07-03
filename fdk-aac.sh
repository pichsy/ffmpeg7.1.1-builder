#!/bin/bash
set -e

NDK_ROOT=/Users/pichs/Android/sdk/ndk/28.0.13004108
API=21
BUILD_DIR=$(pwd)/output/android/$1
SYSROOT=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/sysroot

case "$1" in
    arm64)
        TARGET=aarch64-linux-android
        HOST=aarch64-linux-android
        TOOLCHAIN=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin
        CC=$TOOLCHAIN/${TARGET}${API}-clang
        ;;
    armv7)
        TARGET=armv7a-linux-androideabi
        HOST=arm-linux
        TOOLCHAIN=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin
        CC=$TOOLCHAIN/${TARGET}${API}-clang
        ;;
    *)
        echo "Usage: $0 [arm64|armv7]"
        exit 1
        ;;
esac

mkdir -p $BUILD_DIR

echo "=== 编译 fdk-aac for $1 ==="
cd fdk-aac

[ -f Makefile ] && make distclean || true
[ -f configure ] || ./autogen.sh

export CC=$CC
./configure --prefix=$BUILD_DIR --host=$HOST --disable-shared --enable-static --with-sysroot=$SYSROOT
make -j$(sysctl -n hw.ncpu)
make install
cd ..

echo "fdk-aac 编译完成，安装路径：$BUILD_DIR"
