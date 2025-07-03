#!/bin/bash
set -e

ARCH=$1
if [ -z "$ARCH" ]; then
    echo "❌ 使用方法: $0 [arm64|armv7]"
    exit 1
fi

# 修改为你的 NDK 路径
NDK_ROOT=/Users/pichs/Android/sdk/ndk/28.0.13004108
API=21
FFMPEG_DIR=$(pwd)/ffmpeg
SYSROOT=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/sysroot

# 映射到标准的Android架构目录名称
case "$ARCH" in
    arm64)
        CPU=armv8-a
        ANDROID_ARCH=arm64-v8a
        CC=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android$API-clang
        ;;
    armv7)
        CPU=armv7-a
        ANDROID_ARCH=armeabi-v7a
        CC=$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin/armv7a-linux-androideabi$API-clang
        ;;
    *)
        echo "❌ 不支持的架构: $ARCH"
        exit 1
        ;;
esac

# 使用标准的Android架构目录名称
BUILD_DIR=$(pwd)/output/android/$ANDROID_ARCH
# 依赖库仍然从原来的目录读取
DEPS_DIR=$(pwd)/output/android/$ARCH
INCLUDE_DIR=$DEPS_DIR/include
LIB_DIR=$DEPS_DIR/lib

echo "==> 开始编译 FFmpeg for $ARCH ($ANDROID_ARCH)"
echo "==> NDK路径: $NDK_ROOT"
echo "==> 输出目录: $BUILD_DIR"
echo "==> 依赖 include 目录: $INCLUDE_DIR"
echo "==> 依赖 lib 目录: $LIB_DIR"
echo "==> 使用编译器: $CC"

if [ ! -d "$INCLUDE_DIR" ] || [ ! -d "$LIB_DIR" ]; then
    echo "❌ 依赖库目录不存在，请先编译相关依赖库 (x264, x265, fdk-aac, mp3lame, opus, vpx)"
    exit 1
fi

# 确保输出目录存在
mkdir -p "$BUILD_DIR"

# 配置 pkg-config 环境
export PKG_CONFIG_PATH=$LIB_DIR/pkgconfig
export PKG_CONFIG_LIBDIR=$LIB_DIR/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=/

echo "==> PKG_CONFIG_PATH: $PKG_CONFIG_PATH"

# 验证关键库的pkg-config
echo "==> 验证依赖库的pkg-config..."
CRITICAL_LIBS="opus x264 x265 fdk-aac mp3lame"
for lib in $CRITICAL_LIBS; do
    if pkg-config --exists "$lib" 2>/dev/null; then
        version=$(pkg-config --modversion "$lib" 2>/dev/null)
        echo "✅ $lib: 找到 (版本: $version)"
    else
        echo "❌ $lib: pkg-config 检测失败"
        echo "   检查 $LIB_DIR/pkgconfig/${lib}.pc 文件"
    fi
done

# 检查vpx但不作为必需库
if pkg-config --exists "vpx" 2>/dev/null; then
    version=$(pkg-config --modversion "vpx" 2>/dev/null)
    echo "⚠️  vpx: 找到但暂时禁用 (版本: $version) - 目标文件格式问题"
else
    echo "⚠️  vpx: 未找到或有问题"
fi

cd $FFMPEG_DIR

make clean || true

echo "==> 开始配置FFmpeg..."
./configure \
    --prefix=$BUILD_DIR \
    --target-os=android \
    --arch=$ARCH \
    --cpu=$CPU \
    --cc=$CC \
    --sysroot=$SYSROOT \
    --enable-cross-compile \
    --enable-shared \
    --enable-static \
    --disable-doc \
    --disable-programs \
    --disable-symver \
    --enable-pic \
    --enable-gpl \
    --enable-nonfree \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libfdk_aac \
    --enable-libmp3lame \
    --enable-libopus \
    --disable-libvpx \
    --extra-cflags="-I$INCLUDE_DIR" \
    --extra-ldflags="-L$LIB_DIR"

echo "==> 开始编译..."
make -j$(sysctl -n hw.ncpu)

echo "==> 安装..."
make install

echo "==> 创建Android NDK标准目录结构..."
# 创建标准的NDK目录结构
mkdir -p "$BUILD_DIR/libs/$ANDROID_ARCH"

# 移动.so文件到libs目录
mv "$BUILD_DIR/lib"/*.so "$BUILD_DIR/libs/$ANDROID_ARCH/" 2>/dev/null || true

# 头文件已经由make install自动安装到$BUILD_DIR/include/目录

echo "✅ FFmpeg 编译完成，输出目录: $BUILD_DIR"
echo "📁 库文件位置: $BUILD_DIR/libs/$ANDROID_ARCH/"
echo "📁 头文件位置: $BUILD_DIR/include/"
echo "⚠️  注意：libvpx 已禁用，如需使用请重新编译libvpx库"

echo ""
echo "==> 文件列表:"
echo "📦 .so库文件:"
ls -la "$BUILD_DIR/libs/$ANDROID_ARCH"/*.so 2>/dev/null | awk '{printf "   %s (%s)\n", $9, $5}'
echo ""
echo "📂 头文件目录:"
ls -la "$BUILD_DIR/include"/libav* "$BUILD_DIR/include"/libsw* "$BUILD_DIR/include"/libpostproc 2>/dev/null | awk '{printf "   %s/\n", $9}'
