#!/bin/bash

ARCH=$1

BUILD_ROOT=$(pwd)/output/android/$ARCH

if [ "$ARCH" == "arm64" ]; then
  TARGET="arm64-darwin-gcc"   # 注意 libvpx 官方一般用这个 target 或 android-arm64 视版本而定
  CPU="cortex-a53"
  SYSROOT=$NDK/platforms/android-21/arch-arm64
  CROSS_PREFIX=$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android21-
  EXTRA_CFLAGS="-march=armv8-a"
else
  echo "Unsupported arch: $ARCH"
  exit 1
fi

echo "=== 编译 libvpx for $ARCH ==="
cd libvpx

# 清理
git reset --hard
git clean -fdx

./configure \
  --prefix=$BUILD_ROOT \
  --target=$TARGET \
  --cpu=$CPU \
  --enable-pic \
  --disable-examples \
  --disable-tools \
  --disable-docs \
  --enable-vp8 \
  --enable-vp9 \
  --disable-debug \
  --enable-static \
  --disable-shared \
  --as=yasm \
  --extra-cflags="$EXTRA_CFLAGS"

make -j$(sysctl -n hw.ncpu)
make install

cd ..
echo "libvpx for $ARCH build finished, output in $BUILD_ROOT"
