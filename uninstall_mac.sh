#!/usr/bin/env bash

if [ -z "$APP_NAME" ]
then
	APP_NAME="@@NAME@@"
fi 

echo "====== delete lucterios #@@BUILD@@ ======"
rm -f /usr/local/bin/launch_lucterios
rm -f /usr/local/bin/launch_lucterios_gui
rm -rf $HOME/lucterios2
[ -d "/var/lucterios2/" ]  && sudo rm -rf /var/lucterios2/
rm -rf /Applications/$APP_NAME.*
echo "============ END ============="
exit 0
