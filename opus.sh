#!/bin/bash
set -e

NDK_ROOT=/Users/pichs/Android/sdk/ndk/28.0.13004108
API=21
BUILD_DIR=$(pwd)/output/android/$1
SYSROOT=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/sysroot
# 设置opus版本号
OPUS_VERSION="1.3.1"

case "$1" in
    arm64)
        TARGET=aarch64-linux-android
        HOST=aarch64-linux-android
        TOOLCHAIN=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin
        CC=$TOOLCHAIN/${TARGET}${API}-clang
        CFLAGS="-march=armv8-a -O3"
        ;;
    armv7)
        TARGET=armv7a-linux-androideabi
        HOST=arm-linux-androideabi
        TOOLCHAIN=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin
        CC=$TOOLCHAIN/${TARGET}${API}-clang
        CFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=softfp -O3"
        ;;
    *)
        echo "Usage: $0 [arm64|armv7]"
        exit 1
        ;;
esac

mkdir -p $BUILD_DIR

echo "=== 编译 opus for $1 ==="
cd opus

# 如果有 Makefile，先清理
[ -f Makefile ] && make distclean || true

# 如果没有 configure 脚本，尝试执行 autogen.sh 生成
if [ ! -f configure ]; then
    if [ -f autogen.sh ]; then
        echo "No configure script found, running autogen.sh to generate it..."
        ./autogen.sh
    else
        echo "Error: configure script and autogen.sh not found in opus directory."
        exit 1
    fi
fi

export CC=$CC

./configure --prefix=$BUILD_DIR --host=$HOST --disable-shared --enable-static --with-sysroot=$SYSROOT --enable-custom-modes

make -j$(sysctl -n hw.ncpu)
make install

# 修复opus.pc文件中的版本号
if [ -f "$BUILD_DIR/lib/pkgconfig/opus.pc" ]; then
    echo "修复opus.pc文件中的版本号..."
    sed -i "" "s/Version: unknown/Version: $OPUS_VERSION/g" "$BUILD_DIR/lib/pkgconfig/opus.pc"
    echo "opus.pc版本已修复为 $OPUS_VERSION"
else
    # 创建新的opus.pc文件
    echo "opus.pc 文件未生成，手动创建..."
    mkdir -p $BUILD_DIR/lib/pkgconfig
    cat > $BUILD_DIR/lib/pkgconfig/opus.pc << EOF
prefix=$BUILD_DIR
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include/opus

Name: opus
Description: Opus IETF audio codec
Version: $OPUS_VERSION
Requires:
Conflicts:
Libs: -L\${libdir} -lopus
Libs.private: -lm
Cflags: -I\${includedir}
EOF
    echo "opus.pc 文件已手动创建"
fi

cd ..

# 确保库文件存在
if [ -f "$BUILD_DIR/lib/libopus.a" ]; then
    echo "opus静态库已成功编译"
else
    echo "警告：opus静态库未找到"
fi

echo "opus 编译完成，安装路径：$BUILD_DIR"
echo "现在可以运行 ffmpeg.sh 编译 FFmpeg"
