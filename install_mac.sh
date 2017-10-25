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
	echo "${0##*/}: installation for Lucterios"
	echo "	${0##*/} -h"
	echo "	${0##*/} [-p <packages>] [-n <application_name>]"
	echo "option:"
	echo " -h: show this help"
	echo " -p: define the packages list to install (default: '$PACKAGES')"
	echo " -n: define the application name for shortcut (default: '$APP_NAME')"
	exit 0
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
   \?) echo "Unrecognized parameter -$OPTARG" >&2
       exit 1
       ;;
    :) echo "Option -$OPTARG requires an argument." >&2
       exit 1
       ;;
    esac
done

PIP_OPTION=""
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

echo "====== install lucterios #@@BUILD@@ ======"

echo "install: packages=$PACKAGES application_name=$APP_NAME"

echo
echo "------ check perquisite -------"
echo

if [ ! -z "$(which brew 2>/dev/null)" ]; then
	brew install libxml2 libxslt libjpeg libpng libtiff giflib
	easy_install pip
	brew install python3
	pip3 install --upgrade pip
else
	echo "++++++ brew not installed on Mac OS X! +++++++"
	exit 1
fi

echo
echo "------ configure virtual environment ------"
echo

[ -z "$(which "pip3")" ] && echo "No pip3 found!" && exit 1

PIP_CMD="pip3"
PYTHON_CMD="python3"

set -e

echo "$PYTHON_CMD $(which $PIP_CMD) install $PIP_OPTION virtualenv -U"
$PYTHON_CMD $(which $PIP_CMD) install -U $PIP_OPTION pip virtualenv

mkdir -p $LUCTERIOS_PATH
cd $LUCTERIOS_PATH
echo "$PYTHON_CMD $(which virtualenv) virtual_for_lucterios"
$PYTHON_CMD $(which virtualenv) virtual_for_lucterios

echo
echo "------ install lucterios ------"
echo

. $LUCTERIOS_PATH/virtual_for_lucterios/bin/activate
pip install -U $PIP_OPTION pip 
pip install -I pillow
pip install -U $PIP_OPTION $PACKAGES
lucterios_admin.py refreshall || echo '--no refresh--'
[ -f "$LUCTERIOS_PATH/extra_url" ] || echo "# Pypi server" > "$LUCTERIOS_PATH/extra_url"

echo
echo "------ refresh shortcut ------"
echo
rm -rf $LUCTERIOS_PATH/launch_lucterios.sh
touch $LUCTERIOS_PATH/launch_lucterios.sh
echo "#!/usr/bin/env bash" >> $LUCTERIOS_PATH/launch_lucterios.sh
echo  >> $LUCTERIOS_PATH/launch_lucterios.sh
echo ". $LUCTERIOS_PATH/virtual_for_lucterios/bin/activate" >> $LUCTERIOS_PATH/launch_lucterios.sh
echo "cd $LUCTERIOS_PATH/" >> $LUCTERIOS_PATH/launch_lucterios.sh
if [ -z "$LANG" -o "$LANG" == "C" ]
then
	echo "export LANG=en_US.UTF-8" >> $LUCTERIOS_PATH/launch_lucterios.sh
fi

cp $LUCTERIOS_PATH/launch_lucterios.sh $LUCTERIOS_PATH/launch_lucterios_gui.sh
echo "lucterios_gui.py" >> $LUCTERIOS_PATH/launch_lucterios_gui.sh
chmod +x $LUCTERIOS_PATH/launch_lucterios_gui.sh

echo 'lucterios_admin.py $@' >> $LUCTERIOS_PATH/launch_lucterios.sh
chmod +x $LUCTERIOS_PATH/launch_lucterios.sh
chmod -R ogu+w $LUCTERIOS_PATH

ln -sf $LUCTERIOS_PATH/launch_lucterios.sh /usr/local/bin/launch_lucterios
ln -sf $LUCTERIOS_PATH/launch_lucterios_gui.sh /usr/local/bin/launch_lucterios_gui


icon_path=$(find "$LUCTERIOS_PATH/virtual_for_lucterios" -name "$APP_NAME.png" | head -n 1)

APPDIR="$PWD/$APP_NAME.command"
echo '#!/usr/bin/env bash' > $APPDIR
echo 'launch_lucterios_gui' >> $APPDIR
chmod ogu+rx "$APPDIR"

$PYTHON_CMD $(which $PIP_CMD) install -U $PIP_OPTION py2app
rm -rf MyIcon.iconset
if [ ! -z "$icon_path" ]
then
    mkdir MyIcon.iconset
    sips -z 16 16     $icon_path --out "MyIcon.iconset/icon_16x16.png"
    sips -z 32 32     $icon_path --out "MyIcon.iconset/icon_16x16@2x.png"
    sips -z 32 32     $icon_path --out "MyIcon.iconset/icon_32x32.png"
    sips -z 64 64     $icon_path --out "MyIcon.iconset/icon_32x32@2x.png"
    sips -z 128 128   $icon_path --out "MyIcon.iconset/icon_128x128.png"
    sips -z 256 256   $icon_path --out "MyIcon.iconset/icon_128x128@2x.png"
    sips -z 256 256   $icon_path --out "MyIcon.iconset/icon_256x256.png"
    sips -z 512 512   $icon_path --out "MyIcon.iconset/icon_256x256@2x.png"
    sips -z 512 512   $icon_path --out "MyIcon.iconset/icon_512x512.png"
    cp $icon_path MyIcon.iconset/icon_512x512@2x.png
    iconutil -c icns MyIcon.iconset
    rm -rf MyIcon.iconset
fi

py_run="$PWD/run.py"
rm -rf $py_run
echo "# launcher for lucterios GUI" >> $py_run
echo "import os" >> $py_run
echo "os.chdir('$PWD')" >> $py_run
for var_item in LC_ALL LC_CTYPE LANG LANGUAGE
do 
	if [ ! -z "${!var_item}" ]
	then 
		echo "os.environ['$var_item']='${!var_item}'"
	fi
done
echo "" >> $py_run
echo "import lucterios.install.lucterios_gui" >> $py_run
echo "lucterios.install.lucterios_gui.main()" >> $py_run
echo "" >> $py_run

py2app_setup="$LUCTERIOS_PATH/setup.py"
rm -rf $py2app_setup
echo "# setup" >> $py2app_setup
echo "from setuptools import setup" >> $py2app_setup
echo "setup(" >> $py2app_setup
echo "	name='$APP_NAME'," >> $py2app_setup
echo "	app=['run.py']," >> $py2app_setup
echo "	setup_requires=['py2app']," >> $py2app_setup
echo ")" >> $py2app_setup
if [ -f "MyIcon.icns" ]
then
    $PYTHON_CMD $py2app_setup py2app --iconfile MyIcon.icns --use-pythonpath --site-packages -A
else
    $PYTHON_CMD $py2app_setup py2app --use-pythonpath --site-packages -A
fi
site_new_name="site_mac"
cat "$LUCTERIOS_PATH/dist/$APP_NAME.app/Contents/Resources/__boot__.py" | sed "s|import os, site|import os, $site_new_name|g" | sed "s|site\.|$site_new_name.|g" | sed "s|import site,|import $site_new_name,|g" > "$LUCTERIOS_PATH/__boot__.py"
echo "import sys, os" > "$LUCTERIOS_PATH/dist/$APP_NAME.app/Contents/Resources/__boot__.py"
echo "sys.path.append(os.environ['RESOURCEPATH'])" >> "$LUCTERIOS_PATH/dist/$APP_NAME.app/Contents/Resources/__boot__.py"
cat "$LUCTERIOS_PATH/__boot__.py" >> "$LUCTERIOS_PATH/dist/$APP_NAME.app/Contents/Resources/__boot__.py"
rm -rf "$LUCTERIOS_PATH/__boot__.py"
mv "$LUCTERIOS_PATH/dist/$APP_NAME.app/Contents/Resources/site.py" "$LUCTERIOS_PATH/dist/$APP_NAME.app/Contents/Resources/$site_new_name.py"
rm -rf "$LUCTERIOS_PATH/dist/$APP_NAME.app/Contents/Resources/__pycache__"

rm -rf "/Applications/$APP_NAME.app"
mv "$LUCTERIOS_PATH/dist/$APP_NAME.app" "/Applications/$APP_NAME.app"
chmod -R ogu+rx "/Applications/$APP_NAME.app"

rm -rf "$LUCTERIOS_PATH/dist"
rm -rf "$LUCTERIOS_PATH/build"

chmod -R ogu+rw "$LUCTERIOS_PATH"

echo "============ END ============="
exit 0
