#!/usr/bin/env bash

if [ "$(id -u)" != "0" ]; then
   echo ">>> This script must be run as 'super user' <<<" 1>&2
   [ -z "$(which sudo)" ] && exit 1
   sudo -E -H $0 $@
   exit $!
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

echo "====== install lucterios #@@BUILD@@ ======"

echo "install: packages=$PACKAGES application_name=$APP_NAME"

echo
echo "------ check perquisite -------"
echo

if [ ! -z "$(which apt-get 2>/dev/null)" ]; then  # DEB linux like
	apt-get install -y libxml2-dev libxslt-dev libjpeg-dev libfreetype6 libfreetype6-dev zlib1g-dev
	apt-get install -y python3-pip python3-dev
	apt-get install -y python3-tk 'python3-imaging|python3-pil'
else if [ ! -z "$(which dnf 2>/dev/null)" ]; then # RPM unix/linux like
	dnf install -y libxml2-devel libxslt-devel libjpeg-devel gcc
	dnf install -y libfreetype6 libfreetype6-devel
	dnf install -y python3-devel python3-imaging python3-tkinter	
else if [ ! -z "$(which yum 2>/dev/null)" ]; then # RPM unix/linux like
	yum install -y libxml2-devel libxslt-devel libjpeg-devel gcc
	yum install -y libfreetype6 libfreetype6-devel
	yum install -y python3-devel python3-imaging python3-tkinter	
	easy_install pip
else
	echo "++++++ Unix/Linux distribution not available for this script! +++++++"
fi; fi; fi

echo
echo "------ configure virtual environment ------"
echo

LUCTERIOS_PATH="/var/lucterios2"
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

if [ -d "/usr/share/applications" ]
then
	LAUNCHER="/usr/share/applications/lucterios.desktop"
	echo "[Desktop Entry]" > $LAUNCHER
	echo "Name=$APP_NAME" >> $LAUNCHER
	echo "Comment=$APP_NAME installer" >> $LAUNCHER
	echo "Exec=$LUCTERIOS_PATH/launch_lucterios_gui.sh" >> $LAUNCHER
	echo "Icon=$icon_path" >> $LAUNCHER
	echo "Terminal=false" >> $LAUNCHER
	echo "Type=Application" >> $LAUNCHER
	echo "Categories=Office" >> $LAUNCHER
fi

chmod -R ogu+rw "$LUCTERIOS_PATH"

echo "============ END ============="
exit 0
