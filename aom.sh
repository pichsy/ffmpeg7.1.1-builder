#!/bin/bash
set -e

NDK_ROOT=/Users/pichs/Android/sdk/ndk/28.0.13004108
API=21
BUILD_DIR=$(pwd)/output/android/$1
AOM_SRC=$(pwd)/aom

case "$1" in
    arm64)
        ABI=arm64-v8a
        TOOLCHAIN_FILE=$NDK_ROOT/build/cmake/android.toolchain.cmake
        CMAKE_PARAMS="-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE \
                     -DANDROID_ABI=$ABI \
                     -DANDROID_PLATFORM=android-$API \
                     -DANDROID_STL=c++_static \
                     -DENABLE_NEON=ON \
                     -DENABLE_CCACHE=ON"
        ;;
    armv7)
        ABI=armeabi-v7a
        TOOLCHAIN_FILE=$NDK_ROOT/build/cmake/android.toolchain.cmake
        CMAKE_PARAMS="-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE \
                     -DANDROID_ABI=$ABI \
                     -DANDROID_PLATFORM=android-$API \
                     -DANDROID_STL=c++_static \
                     -DENABLE_NEON=ON \
                     -DENABLE_CCACHE=ON"
        ;;
    x86)
        ABI=x86
        TOOLCHAIN_FILE=$NDK_ROOT/build/cmake/android.toolchain.cmake
        CMAKE_PARAMS="-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE \
                     -DANDROID_ABI=$ABI \
                     -DANDROID_PLATFORM=android-$API \
                     -DANDROID_STL=c++_static \
                     -DENABLE_CCACHE=ON"
        ;;
    x86_64)
        ABI=x86_64
        TOOLCHAIN_FILE=$NDK_ROOT/build/cmake/android.toolchain.cmake
        CMAKE_PARAMS="-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE \
                     -DANDROID_ABI=$ABI \
                     -DANDROID_PLATFORM=android-$API \
                     -DANDROID_STL=c++_static \
                     -DENABLE_CCACHE=ON"
        ;;
    *)
        echo "用法: $0 [arm64|armv7|x86|x86_64]"
        exit 1
        ;;
esac

# 创建构建目录
mkdir -p $BUILD_DIR/build

echo "=== 编译 AOM for $1 ==="

if [ ! -d "$AOM_SRC" ]; then
    echo "错误：未找到 AOM 源码目录 $AOM_SRC"
    exit 1
fi

# CMake配置
cd $BUILD_DIR/build
cmake $AOM_SRC \
    $CMAKE_PARAMS \
    -DCMAKE_INSTALL_PREFIX=$BUILD_DIR \
    -DCONFIG_PIC=1 \
    -DCONFIG_AV1_ENCODER=1 \
    -DCONFIG_AV1_DECODER=1 \
    -DENABLE_DOCS=0 \
    -DENABLE_TESTS=0 \
    -DENABLE_TOOLS=0 \
    -DBUILD_SHARED_LIBS=0

# 编译
cmake --build . -j$(sysctl -n hw.ncpu)

# 安装
cmake --install .

echo "AOM 编译完成，安装路径：$BUILD_DIR" 