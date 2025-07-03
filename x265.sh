#!/bin/bash
set -e

NDK_ROOT=/Users/pichs/Android/sdk/ndk/28.0.13004108
API=21
BUILD_DIR=$(pwd)/output/android/$1

case "$1" in
    arm64)
        ANDROID_ABI=arm64-v8a
        ANDROID_ARCH=aarch64
        ;;
    armv7)
        ANDROID_ABI=armeabi-v7a
        ANDROID_ARCH=arm
        ;;
    *)
        echo "Usage: $0 [arm64|armv7]"
        exit 1
        ;;
esac

echo "=== 编译 x265 for $1 ==="
# 创建编译目录
mkdir -p x265_git/build/android
cd x265_git/build/android
rm -rf *

# 设置编译环境
export ANDROID_NDK=$NDK_ROOT
export TOOLCHAIN=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64

cmake -DCMAKE_TOOLCHAIN_FILE=$NDK_ROOT/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=$ANDROID_ABI \
    -DANDROID_PLATFORM=android-$API \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$BUILD_DIR \
    -DENABLE_SHARED=OFF \
    -DENABLE_STATIC=ON \
    -DCROSS_COMPILE_ARM=ON \
    -DENABLE_ASSEMBLY=OFF \
    -DENABLE_CLI=OFF \
    -DANDROID_ARM_MODE=arm \
    -DANDROID_STL=c++_static ../../source

make -j$(sysctl -n hw.ncpu)
make install
cd ../../..

echo "x265 编译完成，安装路径：$BUILD_DIR"
