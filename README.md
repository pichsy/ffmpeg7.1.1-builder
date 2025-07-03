# ffmpeg7.1.1-builder




# 编译最后目录在 output下




# 编译须知

-  git clone https://github.com/mstorsjo/fdk-aac.git
- git clone https://code.videolan.org/videolan/x264.git
- git clone https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
- tar xzf lame-3.100.tar.gz && mv lame-3.100 lame
- git clone https://git.ffmpeg.org/ffmpeg.git
- git clone https://bitbucket.org/multicoreware/x265_git.git
- opus库：https://ftp.osuosl.org/pub/xiph/releases/opus/opus-1.5.2.tar.gz
-  注意：libvpx v1.15.2，此库没用
- git clone https://chromium.googlesource.com/webm/libvpx 
- 注意：aom，v3.12.1，此库没用
- git clone https://aomedia.googlesource.com/aom



把这些库都下载下来，再按脚本一个一个编译。最后编译ffmpeg即可。