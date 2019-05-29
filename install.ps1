#requires -version 2.0
param (
    [string]$packages = "@@PACKAGE@@",
    [string]$app_name = "@@NAME@@",
    [switch]$help = $false
)

function Test-Admin {
  $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-executionpolicy Bypass -noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    exit
}

if ($help) {
	echo "install.ps1: installation for Lucterios"
	echo "	install.ps1 -help"
	echo "	install.ps1 [-packages <packages>] [-app_name <application_name>]"
	echo "option:"
	echo " -help: show this help"
	echo " -packages: define the packages list to install (default: '$packages')"
	echo " -app_name: define the application name for shortcut (default: '$app_name')"
	exit 0
}

Try {

$lucterios_path="c:\lucterios2"

cd $lucterios_path

$env:Path="$lucterios_path\Python;$lucterios_path\Python\Scripts;$env:Path"

echo ""
echo "------ install lucterios #@@BUILD@@ ------"
echo ""

python .\Python\Scripts\get-pip.py -U pip==19.0.* 2>&1 | Out-Null
echo "=> python .\Python\Scripts\get-pip.py -U $packages"
foreach($package in $packages.split()) {
    echo "===> python .\Python\Scripts\get-pip.py -U $package"
	python .\Python\Scripts\get-pip.py -U $package @@PIPOPTION@@
}
python .\Python\Scripts\get-pip.py -U pip==19.0.* 2>&1 | Out-Null
python -m pip list

python Python\Scripts\lucterios_admin.py update | python Python\Scripts\lucterios_admin.py refreshall | Out-Null

echo ""
echo "------ create starter bat ------"
echo ""

if (Test-Path $lucterios_path\launch_lucterios.ps1) {
    del $lucterios_path\launch_lucterios.ps1
}
if (Test-Path $lucterios_path\lucterios_gui.ps1) {
    del $lucterios_path\lucterios_gui.ps1
}
if (Test-Path $lucterios_path\lucterios_admin.ps1) {
    del $lucterios_path\lucterios_admin.ps1
}
if (Test-Path $lucterios_path\virtual_for_lucterios) {
    del -r $lucterios_path\virtual_for_lucterios | Out-Null
}
if (!(Test-Path $lucterios_path\extra_url)) {
    echo "# Pypi servers" | Out-File -Encoding ascii -Append -FilePath $lucterios_path\extra_url
}


echo "#requires -version 2.0" >> $lucterios_path\lucterios_admin.ps1
echo "" >> $lucterios_path\lucterios_admin.ps1
echo "echo '$app_name GUI launcher'" >> $lucterios_path\lucterios_admin.ps1
echo "" >> $lucterios_path\lucterios_admin.ps1
echo "cd $lucterios_path" >> $lucterios_path\lucterios_admin.ps1
echo "" >> $lucterios_path\lucterios_admin.ps1
echo "`$env:Path=`"`$lucterios_path\Python;$lucterios_path\Python\Scripts;$env:Path`"" >> $lucterios_path\lucterios_admin.ps1
echo "`$env:TCL_LIBRARY='$lucterios_path\Python\tcl\tcl8.6'" >> $lucterios_path\lucterios_admin.ps1
echo "`$env:TK_LIBRARY='$lucterios_path\Python\tcl\tcl8.6'" >> $lucterios_path\lucterios_admin.ps1
cp $lucterios_path\lucterios_admin.ps1 $lucterios_path\lucterios_gui.ps1

echo "python Python\Scripts\lucterios_gui.py" >> $lucterios_path\lucterios_gui.ps1
echo "exit" >> $lucterios_path\lucterios_gui.ps1
echo "" >> $lucterios_path\lucterios_gui.ps1

echo "python Python\Scripts\lucterios_admin.py `$args[0] `$args[1] `$args[2] `$args[3] `$args[4] `$args[5] `$args[6] `$args[7] `$args[8] `$args[9]" >> $lucterios_path\lucterios_admin.ps1
echo "exit" >> $lucterios_path\lucterios_admin.ps1
echo "" >> $lucterios_path\lucterios_admin.ps1

echo ""
echo "------ refresh shortcut ------"
echo ""

if (Test-Path $env:Public\Desktop\$app_name.lnk) {
    del $env:Public\Desktop\$app_name.lnk
}

$icon_path = Get-ChildItem -Path "$lucterios_path\python" -Recurse -Filter "$app_name.ico" | Select-Object -First 1 | % { $_.FullName }

$WshShell = New-Object -ComObject WScript.shell
$Shortcut = $WshShell.CreateShortcut("$lucterios_path\$app_name.lnk")
$Shortcut.TargetPath = "PowerShell.exe"
$Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File $lucterios_path\lucterios_gui.ps1"
if (($icon_path -ne "") -and (Test-Path $icon_path)) {
	$Shortcut.IconLocation = "$icon_path"
}
$Shortcut.WindowStyle = 7
$Shortcut.Save()

echo ""
echo "------ refresh permission ------"
echo ""

$acl = Get-Acl $lucterios_path
$sid = new-object System.Security.Principal.SecurityIdentifier "S-1-1-0"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($sid,"FullControl","ContainerInherit,ObjectInherit","None","Allow") 
$acl.SetAccessRule($accessRule) 
$acl | Set-Acl $lucterios_path
$rc=0

}Catch {
    echo ""
    echo "Error:$_.Exception.Message"
    echo ""
    echo "**** $app_name not installed ****"
    $rc=1
}
echo "============ END ============="
echo "Press a key..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""
exit $rc
