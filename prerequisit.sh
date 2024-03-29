#!/bin/bash

set -x

dpkg --add-architecture i386
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl unzip xauth xvfb software-properties-common
sed -i '/kill ".*"/a \
        wait "$XVFBPID" >>"$ERRORFILE" 2>&1
' /usr/bin/xvfb-run
export DISPLAY=:0.0
xdpyinfo -display $DISPLAY > /dev/null || Xvfb $DISPLAY -screen 0 1024x768x16 &

curl https://dl.winehq.org/wine-builds/winehq.key | apt-key add -
add-apt-repository "deb https://dl.winehq.org/wine-builds/debian/ $(lsb_release -c -s) main"
apt-get update
apt-get install -y --no-install-recommends winehq-stable wine32
mkdir -p $HOME/wine/prefix
export WINEPREFIX=$HOME/wine/prefix 
export WINEARCH=win32
export WINEPATH=$HOME/wine
wineboot -u

curl -L  https://sourceforge.net/projects/nsis/files/NSIS%203/3.08/nsis-3.08-setup.exe > nsis-3.08-setup.exe
wine nsis-3.08-setup.exe /S
