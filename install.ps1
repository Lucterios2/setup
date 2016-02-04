#requires -version 2.0
param (
    [string]$extra_url = "@@URL@@",
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
	echo "	install.ps1 [-extra_url <extra_url>] [-packages <packages>] [-app_name <application_name>]"
	echo "option:"
	echo " -help: show this help"
	echo " -extra_url: define a extra url of pypi server (default: '$extra_url')"
	echo " -packages: define the packages list to install (default: '$packages')"
	echo " -app_name: define the application name for shortcut (default: '$app_name')"
	exit 0
}

Try {
echo "====== install lucterios ======"
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo "====== install lucterios ======"

$lucterios_path="c:\lucterios2"
if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
    $url_python = "https://www.python.org/ftp/python/3.4.3/python-3.4.3.amd64.msi"    
    $url_lxml = "https://raw.githubusercontent.com/Lucterios2/core/master/packages/lxml-3.4.4-cp34-none-win_amd64.whl"
    $url_pycrypto = "https://raw.githubusercontent.com/Lucterios2/core/master/packages/pycrypto-2.6.1-cp34-none-win_amd64.whl"
    $lxml_install = "$env:temp\lxml-3.4.4-cp34-none-win_amd64.whl"
    $pycrypto_install = "$env:temp\pycrypto-2.6.1-cp34-none-win_amd64.whl"
} else {
    $url_python = "https://www.python.org/ftp/python/3.4.3/python-3.4.3.msi"
    $url_lxml = "https://raw.githubusercontent.com/Lucterios2/core/master/packages/lxml-3.4.4-cp34-none-win32.whl"
    $url_pycrypto = "https://raw.githubusercontent.com/Lucterios2/core/master/packages/pycrypto-2.6.1-cp34-none-win32.whl"
    $lxml_install = "$env:temp\lxml-3.4.4-cp34-none-win32.whl"
    $pycrypto_install = "$env:temp\pycrypto-2.6.1-cp34-none-win32.whl"
}
$python_install = "$env:temp\python.msi"

Import-Module BitsTransfer

if (!(Test-Path "c:\Python34")) {

    echo ""
    echo "------ download python -------"
    echo ""

    Start-BitsTransfer -Source $url_python -Destination $python_install
    if (!(Test-Path $python_install)) {
        echo "**** Dowload python failed! *****"
        raise
    }echo ""
    echo "------ install python -------"
    echo ""

    msiexec /i $python_install /passive | Out-Null
}

echo ""
echo "------ download and install python tools -------"
echo ""

Start-BitsTransfer -Source $url_lxml -Destination $lxml_install
if (!(Test-Path $lxml_install)) {
    echo "**** Dowload lxml failed! *****"
    raise
}

Start-BitsTransfer -Source $url_pycrypto -Destination $pycrypto_install
if (!(Test-Path $pycrypto_install)) {
    echo "**** Dowload pycrypto failed! *****"
    raise
}

$env:Path="$env:Path;c:\Python34;c:\Python34\Scripts\"
pip install -U virtualenv

echo ""
echo "------ configure virtual environment ------"
echo ""

if (!(Test-Path $lucterios_path)) {
    mkdir $lucterios_path
}
cd $lucterios_path
if (!(Test-Path $lucterios_path\virtual_for_lucterios)) {
	virtualenv virtual_for_lucterios
}

if (!(Test-Path $lucterios_path\virtual_for_lucterios\Scripts\activate)) {
    echo "**** Virtual-Env not created! *****"
    raise
}

echo ""
echo "------ install lucterios ------"
echo ""

.\virtual_for_lucterios\Scripts\activate
pip install -U pip | out-null
pip install -U $lxml_install $pycrypto_install
if ($extra_url -ne '') {
	$extra_host = ([System.Uri]$extra_url).Host
	echo "=> pip install --extra-index-url $extra_url --trusted-host $extra_host -U $packages"
	foreach($package in $packages.split()) {
		pip install --extra-index-url $extra_url --trusted-host $extra_host -U $package
	}
}
else {
	echo "=> pip install -U $packages"
	foreach($package in $packages.split()) {
		pip install -U $package
	}
}

echo ""
echo "------ refresh shortcut ------"
echo ""

if (Test-Path $lucterios_path\launch_lucterios.ps1) {
    del $lucterios_path\launch_lucterios.ps1
}
echo "#requires -version 2.0" >> $lucterios_path\launch_lucterios.ps1
echo "" >> $lucterios_path\launch_lucterios.ps1
echo "echo '$app_name GUI launcher'" >> $lucterios_path\launch_lucterios.ps1
echo "" >> $lucterios_path\launch_lucterios.ps1
echo "cd $lucterios_path" >> $lucterios_path\launch_lucterios.ps1
echo "virtual_for_lucterios\Scripts\activate" >> $lucterios_path\launch_lucterios.ps1
echo "" >> $lucterios_path\launch_lucterios.ps1
echo "`$env:Path=`"`$env:Path;c:\Python34;c:\Python34\DLLs`"" >> $lucterios_path\launch_lucterios.ps1
echo "`$env:TCL_LIBRARY='c:\Python34\tcl\tcl8.6'" >> $lucterios_path\launch_lucterios.ps1
echo "`$env:TK_LIBRARY='c:\Python34\tcl\tcl8.6'" >> $lucterios_path\launch_lucterios.ps1
if ( $extra_url -ne '') {
	echo "`$env:extra_url='$extra_url'" >> $lucterios_path\launch_lucterios.ps1
}
echo "python virtual_for_lucterios\Scripts\lucterios_gui.py" >> $lucterios_path\launch_lucterios.ps1
echo "exit" >> $lucterios_path\launch_lucterios.ps1
echo "" >> $lucterios_path\launch_lucterios.ps1

if (Test-Path $env:Public\Desktop\$app_name.lnk) {
    del $env:Public\Desktop\$app_name.lnk
}

$icon_path = Get-ChildItem -Path "$lucterios_path\virtual_for_lucterios" -Recurse -Filter "$app_name.ico" | Select-Object -First 1 | % { $_.FullName }

$WshShell = New-Object -ComObject WScript.shell
$Shortcut = $WshShell.CreateShortcut("$lucterios_path\$app_name.lnk")
$Shortcut.TargetPath = "PowerShell.exe"
$Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File $lucterios_path\launch_lucterios.ps1"
$Shortcut.IconLocation = "$icon_path"
$Shortcut.WindowStyle = 7
$Shortcut.Save()
copy $lucterios_path\$app_name.lnk $env:Public\Desktop\$app_name.lnk

$acl = Get-Acl $lucterios_path
$permission = "everyone","full","ContainerInherit,ObjectInherit","none","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission 
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
