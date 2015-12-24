#!/usr/bin/env bash

if [ "$(id -u)" != "0" ]; then
   echo ">>> This script must be run as 'super user' <<<" 1>&2
   [ -z "$(which sudo)" ] && exit 1
   sudo -E -H $0 $@
   exit $!
fi

EXTRA_URL="@@URL@@"
PACKAGES="@@PACKAGE@@"
APP_NAME="@@NAME@@"

function usage
{
	echo "${0##*/}: installation for Lucterios"
	echo "	${0##*/} -h"
	echo "	${0##*/} [-e <extra_url>] [-p <packages>] [-n <application_name>]"
	echo "option:"
	echo " -h: show this help"
	echo " -e: define a extra url of pypi server (default: '$EXTRA_URL')"
	echo " -p: define the packages list to install (default: '$PACKAGES')"
	echo " -n: define the application name for shortcut (default: '$APP_NAME')"
	exit 0
}

while getopts "e:i:p:n:h" opt ; do
    case $opt in
    e) EXTRA_URL="$OPTARG"
       ;;
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

echo "====== install lucterios ======"

echo "install: extra_url=$EXTRA_URL packages=$PACKAGES application_name=$APP_NAME"

echo
echo "------ check perquisite -------"
echo

if [ ! -z "$(which apt-get 2>/dev/null)" ]; then  # DEB linux like
	apt-get install -y libxml2-dev libxslt-dev libjpeg-dev libfreetype6 libfreetype6-dev zlib1g-dev
	apt-get install -y python-pip python-dev
	apt-get install -y python3-pip python3-dev
	apt-get install -y python-tk python-imaging
	apt-get install -y python3-tk 'python3-imaging|python3-pil'
else if [ ! -z "$(which dnf 2>/dev/null)" ]; then # RPM unix/linux like
	dnf install -y libxml2-devel libxslt-devel libjpeg-devel gcc
	dnf install -y libfreetype6 libfreetype6-devel
	dnf install -y python-devel python-imaging tkinter	
	dnf install -y python3-devel python3-imaging python3-tkinter	
else if [ ! -z "$(which yum 2>/dev/null)" ]; then # RPM unix/linux like
	yum install -y libxml2-devel libxslt-devel libjpeg-devel gcc
	yum install -y libfreetype6 libfreetype6-devel
	yum install -y python-devel python-imaging tkinter	
	yum install -y python3-devel python3-imaging python3-tkinter	
	easy_install pip
else if [ ! -z "$(which brew 2>/dev/null)" ]; then # Mac OS X
	brew_perm=`stat -c "%G:%U" $(which brew)`
	chown root:wheel $(which brew)
	brew install libxml2 libxslt
	easy_install pip
	brew install python3
	chown $brew_perm $(which brew)
	pip3 install --upgrade pip
else
	echo "++++++ Unix/Linux distribution not available for this script! +++++++"
fi; fi; fi; fi

echo
echo "------ configure virtual environment ------"
echo

PIP_CMD=
PYTHON_CMD=
for pip_iter in 3 2
do
	 if [ -z "$PIP_CMD" -a ! -z "$(which "pip$pip_iter")" ]
	 then
	 	PIP_CMD="pip$pip_iter"
	 	PYTHON_CMD="python$pip_iter"
	 fi 
done
[ -z "$PIP_CMD" ] && echo "No pip found!" && exit 1

set -e

echo "$PYTHON_CMD $(which $PIP_CMD) install $PIP_OPTION virtualenv -U"
$PYTHON_CMD $(which $PIP_CMD) install -U $PIP_OPTION pip virtualenv

mkdir -p /var/lucterios2
cd /var/lucterios2
echo "$PYTHON_CMD $(which virtualenv) virtual_for_lucterios"
$PYTHON_CMD $(which virtualenv) virtual_for_lucterios

echo
echo "------ install lucterios ------"
echo

. /var/lucterios2/virtual_for_lucterios/bin/activate
[ ! -z "$EXTRA_URL" ] && PIP_OPTION="$PIP_OPTION --extra-index-url $EXTRA_URL --trusted-host $(echo $EXTRA_URL | awk -F/ '{print $3}')"
pip install -U $PIP_OPTION $PACKAGES

echo
echo "------ refresh shortcut ------"
echo
rm -rf /var/lucterios2/launch_lucterios.sh
touch /var/lucterios2/launch_lucterios.sh
echo "#!/usr/bin/env bash" >> /var/lucterios2/launch_lucterios.sh
echo  >> /var/lucterios2/launch_lucterios.sh
echo ". /var/lucterios2/virtual_for_lucterios/bin/activate" >> /var/lucterios2/launch_lucterios.sh
echo "cd /var/lucterios2/" >> /var/lucterios2/launch_lucterios.sh
if [ ! -z "$EXTRA_URL" ]
then
	echo "export extra_url='$EXTRA_URL'" >> /var/lucterios2/launch_lucterios.sh
fi
if [ -z "$LANG" -o "$LANG" == "C" ]
then
	echo "export LANG=en_US.UTF-8" >> /var/lucterios2/launch_lucterios.sh
fi

cp /var/lucterios2/launch_lucterios.sh /var/lucterios2/launch_lucterios_gui.sh
echo "lucterios_gui.py" >> /var/lucterios2/launch_lucterios_gui.sh
chmod +x /var/lucterios2/launch_lucterios_gui.sh

echo 'lucterios_admin.py $@' >> /var/lucterios2/launch_lucterios.sh
chmod +x /var/lucterios2/launch_lucterios.sh
chmod -R ogu+w /var/lucterios2

ln -sf /var/lucterios2/launch_lucterios.sh /usr/local/bin/launch_lucterios
ln -sf /var/lucterios2/launch_lucterios_gui.sh /usr/local/bin/launch_lucterios_gui


icon_path=$(find "/var/lucterios2/virtual_for_lucterios" -name "$APP_NAME.png" | head -n 1)

if [ -d "/usr/share/applications" ]
then
	LAUNCHER="/usr/share/applications/lucterios.desktop"
	echo "[Desktop Entry]" > $LAUNCHER
	echo "Name=$APP_NAME" >> $LAUNCHER
	echo "Comment=$APP_NAME installer" >> $LAUNCHER
	echo "Exec=/var/lucterios2/launch_lucterios_gui.sh" >> $LAUNCHER
	echo "Icon=$icon_path" >> $LAUNCHER
	echo "Terminal=false" >> $LAUNCHER
	echo "Type=Application" >> $LAUNCHER
	echo "Categories=Office" >> $LAUNCHER
fi
if [ "${OSTYPE:0:6}" == "darwin" ]
then
    APPDIR="$PWD/$APP_NAME.command"
    echo '#!/usr/bin/env bash' > $APPDIR
    echo 'launch_lucterios_gui' >> $APPDIR
    chmod ogu+rx "$APPDIR"

    $PYTHON_CMD $(which $PIP_CMD) install -U $PIP_OPTION py2app
    rm -rf MyIcon.iconset
    if [ -f $icon_path ]
    then
        mkdir MyIcon.iconset
        sips -z 16 16     $icon_path --out MyIcon.iconset/icon_16x16.png
        sips -z 32 32     $icon_path --out MyIcon.iconset/icon_16x16@2x.png
        sips -z 32 32     $icon_path --out MyIcon.iconset/icon_32x32.png
        sips -z 64 64     $icon_path --out MyIcon.iconset/icon_32x32@2x.png
        sips -z 128 128   $icon_path --out MyIcon.iconset/icon_128x128.png
        sips -z 256 256   $icon_path --out MyIcon.iconset/icon_128x128@2x.png
        sips -z 256 256   $icon_path --out MyIcon.iconset/icon_256x256.png
        sips -z 512 512   $icon_path --out MyIcon.iconset/icon_256x256@2x.png
        sips -z 512 512   $icon_path --out MyIcon.iconset/icon_512x512.png
        cp $icon_path MyIcon.iconset/icon_512x512@2x.png
        iconutil -c icns MyIcon.iconset
        rm -rf MyIcon.iconset
    fi

    py_run="$PWD/run.py"
    rm -rf $py_run
    echo "# launcher for lucterios GUI" >> $py_run
    echo "import os" >> $py_run
    echo "os.chdir('$PWD')" >> $py_run
    if [ ! -z "$EXTRA_URL" ]
    then
	echo "os.environ['extra_url']='$EXTRA_URL'" >> $py_run
    fi
    echo "" >> $py_run
    echo "from lucterios.install.lucterios_gui import LucteriosMainForm" >> $py_run
    echo "from lucterios.install.lucterios_admin import setup_from_none" >> $py_run
    echo "setup_from_none()" >> $py_run
    echo "lct_form = LucteriosMainForm()" >> $py_run
    echo "lct_form.execute()" >> $py_run
    echo "" >> $py_run

    py2app_setup="/var/lucterios2/setup.py"
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
    cat "/var/lucterios2/dist/$APP_NAME.app/Contents/Resources/__boot__.py" | sed "s|import os, site|import os, $site_new_name|g" | sed "s|site\.|$site_new_name.|g" | sed "s|import site,|import $site_new_name,|g" > "/var/lucterios2/__boot__.py"
    echo "import sys, os" > "/var/lucterios2/dist/$APP_NAME.app/Contents/Resources/__boot__.py"
    echo "sys.path.append(os.environ['RESOURCEPATH'])" >> "/var/lucterios2/dist/$APP_NAME.app/Contents/Resources/__boot__.py"
    cat "/var/lucterios2/__boot__.py" >> "/var/lucterios2/dist/$APP_NAME.app/Contents/Resources/__boot__.py"
    rm -rf "/var/lucterios2/__boot__.py"
    mv "/var/lucterios2/dist/$APP_NAME.app/Contents/Resources/site.py" "/var/lucterios2/dist/$APP_NAME.app/Contents/Resources/$site_new_name.py"
    rm -rf "/var/lucterios2/dist/$APP_NAME.app/Contents/Resources/__pycache__"

    rm -rf "/Applications/$APP_NAME.app"
    mv "/var/lucterios2/dist/$APP_NAME.app" "/Applications/$APP_NAME.app"
    chmod -R ogu+rx "/Applications/$APP_NAME.app"

    rm -rf "/var/lucterios2/dist"
    rm -rf "/var/lucterios2/build"
fi

chmod -R ogu+rw "/var/lucterios2"

echo "============ END ============="
exit 0
