#!/bin/bash
# Author: omega552003 Reference: https://zdoom.org/wiki/Compile_GZDoom_on_Linux
# Date: 2024Jun18 Build: 4.12.2
# GZDoom Compiler and installer
# Note: WADs, PK3s, PK7s, ZIPs etc should be put in ~/.config/gzdoom 

mkdir ~/gzdoom &&
cd ~/gzdoom

# Dependancies
dnf install gcc-c++ make cmake SDL2-devel git zlib-devel bzip2-devel libjpeg-turbo-devel fluidsynth-devel game-music-emu-devel openal-soft-devel libmpg123-devel libsndfile-devel gtk3-devel timidity++ nasm mesa-libGL-devel tar SDL-devel glew-devel libvpx-devel

# ZMusic
mkdir -pv zmusic_build
cd zmusic_build &&
git clone https://github.com/ZDoom/ZMusic.git zmusic &&
mkdir -pv zmusic/build
cd ./zmusic/build &&
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr &&
make
sudo make install

# Prep
cd ~/gzdoom &&
git clone https://github.com/ZDoom/gzdoom.git &&
mkdir -pv gzdoom/build
cd gzdoom
git config --local --add remote.origin.fetch +refs/tags/*:refs/tags/*
git pull
cd ~/gzdoom/gzdoom &&
Tag="$(git tag -l | grep -v 9999 | grep -E '^g[0-9]+([.][0-9]+)*$' | sed 's/^g//' | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 | tail -n 1 | sed 's/^/g/')" &&
git checkout --detach refs/tags/$Tag

# Compile
a='' && [ "$(uname -m)" = x86_64 ] && a=64
c="$(lscpu -p | grep -v '#' | sort -u -t , -k 2,4 | wc -l)" ; [ "$c" -eq 0 ] && c=1
cd ~/gzdoom/gzdoom/build &&
rm -f output_sdl/liboutput_sdl.so &&
if [ -d ../fmodapi44464linux ]; then
f="-DFMOD_LIBRARY=../fmodapi44464linux/api/lib/libfmodex${a}-4.44.64.so -DFMOD_INCLUDE_DIR=../fmodapi44464linux/api/inc"; else
f='-UFMOD_LIBRARY -UFMOD_INCLUDE_DIR'; fi &&
cmake .. -DCMAKE_BUILD_TYPE=Release $f &&
make -j$c

# Install
sudo mkdir -pv /usr/games/gzdoom  /usr/games/gzdoom-alpha
a='' && [ "$(uname -m)" = x86_64 ] && a=64
cd ~/gzdoom/gzdoom/build &&
h="$(sed -n 's/.*#define GIT_HASH "\(.*\)".*/\1/p' ../src/gitinfo.h)" &&
if [ -z "$(git describe --exact-match --tags $h 2>/dev/null)" ]; then
d=-alpha; else d=''; fi &&
o=output_sdl/liboutput_sdl.so && if [ -f "$o" ]; then l="$o ../fmodapi44464linux/api/lib/libfmodex${a}-4.44.64.so"; else l=''; fi &&
if [ game_support.pk3 -nt zd_extra.pk3 ]; then p=game_support.pk3; else p=zd_extra.pk3; fi &&
sudo cp -rv gzdoom gzdoom.pk3 lights.pk3 brightmaps.pk3 game_widescreen_gfx.pk3 $p soundfonts fm_banks $l /usr/games/gzdoom$d/

# launcher
cd ~/gzdoom/gzdoom/build &&
h="$(sed -n 's/.*#define GIT_HASH "\(.*\)".*/\1/p' ../src/gitinfo.h)" &&
if [ -z "$(git describe --exact-match --tags $h 2>/dev/null)" ]; then
d=-alpha; else d=''; fi &&
printf %s "\
#! /bin/sh
# The following command is for GZDoom 2.x or older versions
export LD_LIBRARY_PATH=/usr/games/gzdoom$d
exec /usr/games/gzdoom$d/gzdoom \"\$@\"
" > gzdoom$d.sh &&
chmod 755 gzdoom$d.sh &&
sudo mv -v gzdoom$d.sh /usr/bin/gzdoom$d