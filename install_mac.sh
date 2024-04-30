#!/usr/bin/env bash

if [ "${OSTYPE:0:6}" != "darwin" ]
then # Not Mac OS X
   echo ">>> This script must be run only for Mac OS X (darwin) <<<" 1>&2
   exit 1
fi

PACKAGES="@@PACKAGE@@"
APP_NAME="@@NAME@@"

function usage
{
	echo "${0##*/}: installation for @@NAME@@"
	echo "	${0##*/} -h"
	echo "	${0##*/} [-p <packages>] [-n <application_name>]"
	echo "option:"
	echo " -h: show this help"
	echo " -p: define the packages list to install (default: '$PACKAGES')"
	echo " -n: define the application name for shortcut (default: '$APP_NAME')"
	exit 0
}

function finish_error
{
	msg=$1
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!">&2
	echo " Error: $msg">&2
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!">&2
	exit 1
}

while getopts "i:p:n:h" opt ; do
    case $opt in
    p) PACKAGES="$OPTARG"
       ;;
    n) APP_NAME="$OPTARG"
       ;;
    h) usage $0
       exit 0
       ;;
   \?) finish_error "Unrecognized parameter -$OPTARG"
       ;;
    :) finish_error "Option -$OPTARG requires an argument."
       ;;
    esac
done

PIP_OPTION="@@PIPOPTION@@"
if [ ! -z "$http_proxy" ]
then
	PIP_OPTION="$PIP_OPTION --proxy=$http_proxy"
fi

LUCTERIOS_PATH="$HOME/lucterios2" 
if [ -d "/var/lucterios2" ] # conversion from old installation
then
	if [ -d $LUCTERIOS_PATH ]
	then
		sudo rm -rf "/var/lucterios2"
	else
		sudo mv "/var/lucterios2" "$LUCTERIOS_PATH"  
		sudo chown -R $LOGNAME "$LUCTERIOS_PATH"
	fi
fi

echo "====== install @@NAME@@ #@@BUILD@@ ======"

echo "install: packages=$PACKAGES application_name=$APP_NAME"

echo
echo "------ check perquisite -------"
echo

BREW_PATH="$HOME/lucterios2_brew"
export PKG_CONFIG_PATH="$BREW_PATH/opt/openssl/lib/pkgconfig"
export PATH="$BREW_PATH/bin/:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin"
mkdir -p $BREW_PATH && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C $BREW_PATH

if [ ! -z "$(which brew 2>/dev/null)" ]; then	
	brew update
	brew uninstall --force libxslt || echo '-- no libxslt --'	
	brew uninstall --force libxml2 || echo '-- no libxml2 --'	
	brew uninstall --force libtiff || echo '-- no libtiff --'	
	brew uninstall --force libjpeg || echo '-- no libjpeg --'
	brew uninstall --force libpng || echo '-- no libpng --'	
	brew uninstall --force giflib || echo '-- no giflib --'	
    brew uninstall --force tcl-tk || echo '-- no tcl-tk --'
	brew uninstall --force python3 || echo '-- no python3 --'
	brew install libxml2 libxslt libjpeg libpng libtiff giflib tcl-tk
	brew install python3@3.11
	brew install python-tk@3.11
	brew install python-gdbm@3.11
else
	finish_error "brew not installed on Mac OS X!"
fi

[ -z "$(grep $HOSTNAME /etc/hosts)" ] && sudo sh -c "echo 127.0.0.1 $HOSTNAME >> /etc/hosts"

echo
echo "------ configure virtual environment ------"
echo

py_version=$(python3 --version | egrep -o '([0-9]+\.[0-9]+)')
if [ "$py_version" != "3.7" -a "$py_version" != "3.8" -a "$py_version" != "3.9" -a "$py_version" != "3.10" -a "$py_version" != "3.11" ]
then
    finish_error "Not Python 3.7, 3.8, 3.9, 3.10 or 3.11 (but $py_version) !"
fi
PYTHON_CMD="python3"

set -e

echo "$PYTHON_CMD -m pip install -U $PIP_OPTION pip==24.0 virtualenv"
sudo $PYTHON_CMD -m pip install -U $PIP_OPTION pip==24.0 virtualenv

mkdir -p $LUCTERIOS_PATH
cd $LUCTERIOS_PATH
echo "$PYTHON_CMD -m virtualenv virtual_for_lucterios"
sudo rm -rf virtual_for_lucterios
$PYTHON_CMD -m virtualenv virtual_for_lucterios

echo
echo "------ install @@NAME@@ ------"
echo

. $LUCTERIOS_PATH/virtual_for_lucterios/bin/activate
pip uninstall PIL
pip uninstall Pillow
pip install -U $PIP_OPTION $PACKAGES

[ -z "$(pip list 2>/dev/null | grep 'Django ')" ] && finish_error "Django not installed !"
[ -z "$(pip list 2>/dev/null | grep 'lucterios ')" ]&& finish_error "Lucterios not installed !"

if [ -f virtual_for_lucterios/lib/python$py_version/site-packages/lucterios/framework/settings.py ]
then
	sed 's|!= "nt"|!= "nt" and False|g' virtual_for_lucterios/lib/python$py_version/site-packages/lucterios/framework/settings.py > /tmp/settings.py
	cp /tmp/settings.py virtual_for_lucterios/lib/python$py_version/site-packages/lucterios/framework/settings.py
	rm /tmp/settings.py
fi

lucterios_admin.py update || lucterios_admin.py refreshall || echo '--no update/refresh--'
[ -f "$LUCTERIOS_PATH/extra_url" ] || echo "# Pypi server" > "$LUCTERIOS_PATH/extra_url"

echo
echo "------ refresh shortcut ------"
echo
rm -rf $LUCTERIOS_PATH/launch_lucterios.sh
touch $LUCTERIOS_PATH/launch_lucterios.sh
echo "#!/usr/bin/env bash" >> $LUCTERIOS_PATH/launch_lucterios.sh
echo  >> $LUCTERIOS_PATH/launch_lucterios.sh
echo "export LUCTERIOS_INSTALL='@@BUILD@@'" >> $LUCTERIOS_PATH/launch_lucterios.sh
echo  >> $LUCTERIOS_PATH/launch_lucterios.sh
echo ". $LUCTERIOS_PATH/virtual_for_lucterios/bin/activate" >> $LUCTERIOS_PATH/launch_lucterios.sh
echo "cd $LUCTERIOS_PATH/" >> $LUCTERIOS_PATH/launch_lucterios.sh
if [ -z "$LANG" -o "$LANG" == "C" ]
then
	echo "export LANG=en_US.UTF-8" >> $LUCTERIOS_PATH/launch_lucterios.sh
fi

qt_version=$($PYTHON_CMD -c 'from PyQt5.QtCore import QT_VERSION_STR;print(QT_VERSION_STR)' 2>/dev/null) 

cp $LUCTERIOS_PATH/launch_lucterios.sh $LUCTERIOS_PATH/launch_lucterios_gui.sh
echo "lucterios_gui.py" >> $LUCTERIOS_PATH/launch_lucterios_gui.sh
chmod +x $LUCTERIOS_PATH/launch_lucterios_gui.sh

cp $LUCTERIOS_PATH/launch_lucterios.sh $LUCTERIOS_PATH/launch_lucterios_qt.sh
echo "lucterios_qt.py" >> $LUCTERIOS_PATH/launch_lucterios_qt.sh
chmod +x $LUCTERIOS_PATH/launch_lucterios_qt.sh

echo 'lucterios_admin.py $@' >> $LUCTERIOS_PATH/launch_lucterios.sh
chmod +x $LUCTERIOS_PATH/launch_lucterios.sh
chmod -R ogu+w $LUCTERIOS_PATH

ln -sf $LUCTERIOS_PATH/launch_lucterios.sh /usr/local/bin/launch_lucterios
ln -sf $LUCTERIOS_PATH/launch_lucterios_gui.sh /usr/local/bin/launch_lucterios_gui
ln -sf $LUCTERIOS_PATH/launch_lucterios_qt.sh /usr/local/bin/launch_lucterios_qt


icon_path=$(find "$LUCTERIOS_PATH/virtual_for_lucterios" -name "$APP_NAME.png" | head -n 1)

APPDIR="$PWD/$APP_NAME.command"
echo '#!/usr/bin/env bash' > $APPDIR
echo 'launch_lucterios_gui' >> $APPDIR
chmod ogu+rx "$APPDIR"

rm -rf $APP_NAME.iconset
if [ ! -z "$icon_path" ]
then
    mkdir $APP_NAME.iconset
    sips -z 16 16     $icon_path --out "$APP_NAME.iconset/icon_16x16.png"
    sips -z 32 32     $icon_path --out "$APP_NAME.iconset/icon_16x16@2x.png"
    sips -z 32 32     $icon_path --out "$APP_NAME.iconset/icon_32x32.png"
    sips -z 64 64     $icon_path --out "$APP_NAME.iconset/icon_32x32@2x.png"
    sips -z 128 128   $icon_path --out "$APP_NAME.iconset/icon_128x128.png"
    sips -z 256 256   $icon_path --out "$APP_NAME.iconset/icon_128x128@2x.png"
    sips -z 256 256   $icon_path --out "$APP_NAME.iconset/icon_256x256.png"
    sips -z 512 512   $icon_path --out "$APP_NAME.iconset/icon_256x256@2x.png"
    sips -z 512 512   $icon_path --out "$APP_NAME.iconset/icon_512x512.png"
    cp $icon_path $APP_NAME.iconset/icon_512x512@2x.png
    iconutil -c icns $APP_NAME.iconset
    rm -rf $APP_NAME.iconset
fi

[ -d "/Applications/$APP_NAME.app" ] && rm -rf /Applications/$APP_NAME.app

mkdir -p /Applications/$APP_NAME.app/Contents/MacOS
mkdir -p /Applications/$APP_NAME.app/Contents/Resources
cp $HOME/lucterios2/$APP_NAME.icns /Applications/$APP_NAME.app/Contents/Resources/
echo '#!/usr/bin/env bash' > /Applications/$APP_NAME.app/Contents/MacOS/$APP_NAME
echo '' >> /Applications/$APP_NAME.app/Contents/MacOS/$APP_NAME
echo '. $HOME/lucterios2/virtual_for_lucterios/bin/activate' >> /Applications/$APP_NAME.app/Contents/MacOS/$APP_NAME
echo 'cd $HOME/lucterios2/' >> /Applications/$APP_NAME.app/Contents/MacOS/$APP_NAME
echo 'export LANG=fr_FR.UTF-8' >> /Applications/$APP_NAME.app/Contents/MacOS/$APP_NAME
if [ "${qt_version:0:2}" == "5." ]
then
	echo 'lucterios_qt.py | lucterios_gui.py' >> /Applications/$APP_NAME.app/Contents/MacOS/$APP_NAME
else
	echo 'lucterios_gui.py' >> /Applications/$APP_NAME.app/Contents/MacOS/$APP_NAME
fi
chmod ugo+rx /Applications/$APP_NAME.app/Contents/MacOS/$APP_NAME


echo '<?xml version="1.0" encoding="UTF-8"?>' > /Applications/$APP_NAME.app/Contents/Info.plist
echo '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" " www.apple.com/DTDs/PropertyList-1.0.dtd ">' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo '<plist version="1.0">' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo '<dict>' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo ' <key>CFBundleExecutable</key>' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo ' <string>'$APP_NAME'</string>' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo ' <key>CFBundleGetInfoString</key>' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo ' <string>'$APP_NAME'</string>' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo ' <key>CFBundleIconFile</key>' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo ' <string>'$APP_NAME'.icns</string>' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo ' <key>CFBundleName</key>' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo ' <string>'$APP_NAME'</string>' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo ' <key>CFBundlePackageType</key>' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo ' <string>APPL</string>' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo ' <key>CFBundleShortVersionString</key>' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo ' <string>@@BUILD@@</string>' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo '</dict>' >> /Applications/$APP_NAME.app/Contents/Info.plist
echo '</plist>' >> /Applications/$APP_NAME.app/Contents/Info.plist

chmod -R ogu+rw "$LUCTERIOS_PATH"

echo "=================================="
echo " Installation finish with success."
echo "============== END ==============="
exit 0
