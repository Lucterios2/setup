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
echo "------ check prerequisite -------"
echo

# Fix #8: Detect system Homebrew first (uses bottles = fast), fallback to isolated install
if [ -x "/opt/homebrew/bin/brew" ]; then
	BREW_PATH="/opt/homebrew"
	echo "Using system Homebrew at $BREW_PATH"
elif [ -x "/usr/local/bin/brew" ]; then
	BREW_PATH="/usr/local"
	echo "Using system Homebrew at $BREW_PATH"
else
	BREW_PATH="$HOME/lucterios2_brew"
	echo "No system Homebrew found, installing isolated Homebrew at $BREW_PATH"
	mkdir -p $BREW_PATH && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C $BREW_PATH
fi

export PKG_CONFIG_PATH="$BREW_PATH/opt/openssl/lib/pkgconfig"
export PATH="$BREW_PATH/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin"

if [ ! -z "$(which brew 2>/dev/null)" ]; then
	brew update
	brew install libxml2 libxslt libjpeg libpng libtiff giflib tcl-tk
	brew install cairo pango gdk-pixbuf libffi
	brew install poppler
	# Fix #1: Install generic python3 instead of hardcoded python@3.11
	brew install python3
	brew install python-tk@3 2>/dev/null || brew install python-tk@3.11 2>/dev/null || echo "-- python-tk not available --"
	brew install python-gdbm@3 2>/dev/null || brew install python-gdbm@3.11 2>/dev/null || echo "-- python-gdbm not available --"
else
	finish_error "brew not installed on Mac OS X!"
fi

[ -z "$(grep $HOSTNAME /etc/hosts)" ] && sudo sh -c "echo 127.0.0.1 $HOSTNAME >> /etc/hosts"

echo
echo "------ configure virtual environment ------"
echo

# Fix #2: Numeric version check >= 3.9 instead of whitelist
py_version=$(python3 --version | egrep -o '([0-9]+\.[0-9]+)')
py_major=$(echo $py_version | cut -d. -f1)
py_minor=$(echo $py_version | cut -d. -f2)
if [ "$py_major" -ne 3 ] || [ "$py_minor" -lt 9 ]
then
    finish_error "Python >= 3.9 required (found $py_version)"
fi
PYTHON_CMD="python3"

set -e

# Fix #3: Use stdlib venv instead of sudo pip install virtualenv (PEP 668)
mkdir -p $LUCTERIOS_PATH
cd $LUCTERIOS_PATH
echo "$PYTHON_CMD -m venv virtual_for_lucterios"
rm -rf virtual_for_lucterios
$PYTHON_CMD -m venv virtual_for_lucterios

echo
echo "------ install @@NAME@@ ------"
echo

. $LUCTERIOS_PATH/virtual_for_lucterios/bin/activate

# Fix #4: Add -y flag to avoid blocking on confirmation
pip uninstall -y PIL 2>/dev/null || true
pip uninstall -y Pillow 2>/dev/null || true
pip install -U $PIP_OPTION $PACKAGES

[ -z "$(pip list 2>/dev/null | grep 'Django ')" ] && finish_error "Django not installed !"
[ -z "$(pip list 2>/dev/null | grep 'lucterios ')" ] && finish_error "Lucterios not installed !"

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

qt_version=$($PYTHON_CMD -c 'from PyQt6.QtCore import QT_VERSION_STR;print(QT_VERSION_STR)' 2>/dev/null)

cp $LUCTERIOS_PATH/launch_lucterios.sh $LUCTERIOS_PATH/launch_lucterios_gui.sh
echo "lucterios_gui.py" >> $LUCTERIOS_PATH/launch_lucterios_gui.sh
chmod +x $LUCTERIOS_PATH/launch_lucterios_gui.sh

cp $LUCTERIOS_PATH/launch_lucterios.sh $LUCTERIOS_PATH/launch_lucterios_qt.sh
echo "lucterios_qt.py" >> $LUCTERIOS_PATH/launch_lucterios_qt.sh
chmod +x $LUCTERIOS_PATH/launch_lucterios_qt.sh

echo 'lucterios_admin.py $@' >> $LUCTERIOS_PATH/launch_lucterios.sh
chmod +x $LUCTERIOS_PATH/launch_lucterios.sh
chmod -R ogu+w $LUCTERIOS_PATH

# Fix #5: Symlinks to /usr/local/bin may fail due to SIP — warn but don't fail
ln -sf $LUCTERIOS_PATH/launch_lucterios.sh /usr/local/bin/launch_lucterios 2>/dev/null || echo "Warning: cannot create symlink in /usr/local/bin (SIP). Use full path instead."
ln -sf $LUCTERIOS_PATH/launch_lucterios_gui.sh /usr/local/bin/launch_lucterios_gui 2>/dev/null || echo "Warning: cannot create symlink in /usr/local/bin (SIP). Use full path instead."
ln -sf $LUCTERIOS_PATH/launch_lucterios_qt.sh /usr/local/bin/launch_lucterios_qt 2>/dev/null || echo "Warning: cannot create symlink in /usr/local/bin (SIP). Use full path instead."


icon_path=$(find "$LUCTERIOS_PATH/virtual_for_lucterios" -name "$APP_NAME.png" | head -n 1)

APPDIR="$PWD/$APP_NAME.command"
echo '#!/usr/bin/env bash' > $APPDIR
# Fix #6: Use direct path instead of symlink that may not exist
echo "$LUCTERIOS_PATH/launch_lucterios_gui.sh" >> $APPDIR
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
cp $HOME/lucterios2/$APP_NAME.icns /Applications/$APP_NAME.app/Contents/Resources/ 2>/dev/null || true

# Fix #6 (continued): Use direct path in .app instead of symlink
# Fix #7: Use || (fallback) instead of | (pipe) for lucterios_qt.py / lucterios_gui.py
cat > /Applications/$APP_NAME.app/Contents/MacOS/$APP_NAME << 'LAUNCHER'
#!/usr/bin/env bash

. $HOME/lucterios2/virtual_for_lucterios/bin/activate
cd $HOME/lucterios2/
export LANG=fr_FR.UTF-8
LAUNCHER

if [ "${qt_version:0:2}" == "6." ]
then
	echo 'lucterios_qt.py || lucterios_gui.py' >> /Applications/$APP_NAME.app/Contents/MacOS/$APP_NAME
else
	echo 'lucterios_gui.py' >> /Applications/$APP_NAME.app/Contents/MacOS/$APP_NAME
fi
chmod ugo+rx /Applications/$APP_NAME.app/Contents/MacOS/$APP_NAME

cat > /Applications/$APP_NAME.app/Contents/Info.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
 <key>CFBundleExecutable</key>
 <string>$APP_NAME</string>
 <key>CFBundleGetInfoString</key>
 <string>$APP_NAME</string>
 <key>CFBundleIconFile</key>
 <string>$APP_NAME.icns</string>
 <key>CFBundleName</key>
 <string>$APP_NAME</string>
 <key>CFBundlePackageType</key>
 <string>APPL</string>
 <key>CFBundleShortVersionString</key>
 <string>@@BUILD@@</string>
</dict>
</plist>
PLIST

chmod -R ogu+rw "$LUCTERIOS_PATH"

echo "=================================="
echo " Installation finish with success."
echo "============== END ==============="
exit 0
