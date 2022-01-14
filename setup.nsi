; Lucterios2.nsi
;

;--------------------------------

!include "MUI2.nsh"

!define TEMP $R0
!define TEMP2 $R1

; The name of the installer
Name "@@NAME@@ #@@BUILD@@"

BrandingText "www.sd-libre.fr - Sdl 2022"

; The file to write
OutFile "@@NAME@@_setup.exe"

; The default installation directory
InstallDir c:\Lucterios2

VIProductVersion                 "2.6.0.0"
VIAddVersionKey ProductName      "@@NAME@@"
VIAddVersionKey Comments         "@@NAME@@"
VIAddVersionKey CompanyName      "sd-libre"
VIAddVersionKey LegalCopyright   "GENERAL PUBLIC LICENSE v3"
VIAddVersionKey FileDescription  "@@NAME@@"
VIAddVersionKey FileVersion      2
VIAddVersionKey ProductVersion   2
VIAddVersionKey InternalName     "@@NAME@@"
VIAddVersionKey LegalTrademarks  "@@NAME@@"
VIAddVersionKey OriginalFilename "@@NAME@@_setup.exe"

WindowIcon off
; Icon favicon.ico
; UninstallIcon favicon.ico

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\Lucterios2" "Install_Dir"

; Request application privileges for Windows Vista
RequestExecutionLevel admin ;Require admin rights on NT6+ (When UAC is turned on)

!include LogicLib.nsh

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_LICENSE "License.txt"
  !insertmacro MUI_PAGE_INSTFILES
  !define MUI_FINISHPAGE_TITLE "Installation finie"
  !define MUI_FINISHPAGE_RUN
  !define MUI_FINISHPAGE_RUN_TEXT "Lancer l'application"
  !define MUI_FINISHPAGE_RUN_FUNCTION "LaunchLink"
  !define MUI_FINISHPAGE_SHOWREADME
  !define MUI_FINISHPAGE_SHOWREADME_TEXT "Demarrer automatiquement"
  !define MUI_FINISHPAGE_SHOWREADME_FUNCTION "Startup" 
  !insertmacro MUI_PAGE_FINISH
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  
;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "French"

;--------------------------------
;Installer Sections

Section "install"
  SectionIn RO
  
  SetOutPath "$INSTDIR"
  File "License.txt"

  SetOutPath "$INSTDIR"
  RMDir /r $INSTDIR/Python
  File "install.ps1"
  File /r "Python" 

  ExecWait 'PowerShell.exe -ExecutionPolicy Bypass -File $INSTDIR\install.ps1'

  ; Create uninstall exe
  WriteRegStr HKLM Software\Lucterios2 "Install_Dir" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Lucterios2" "DisplayName" "@@NAME@@"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Lucterios2" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Lucterios2" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Lucterios2" "NoRepair" 1
  WriteUninstaller "uninstall.exe"
  
  ; Create start menu shortcut
  CreateDirectory "$SMPROGRAMS\@@NAME@@"
  CreateShortcut "$SMPROGRAMS\@@NAME@@"\Uninstall.lnk" "$INSTDIR\uninstall.exe"
  CopyFiles $INSTDIR\@@NAME@@.lnk "$SMPROGRAMS\@@NAME@@"

  CopyFiles $INSTDIR\@@NAME@@.lnk "$DESKTOP\@@NAME@@.lnk"

SectionEnd

Function LaunchLink
  ExecShell "" "$INSTDIR\@@NAME@@.lnk"
FunctionEnd

Function Startup
  CopyFiles $INSTDIR\@@NAME@@.lnk "$APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
FunctionEnd

Function .onInit
  UserInfo::GetAccountType
  pop $0
  ${If} $0 != "admin" ;Require admin rights on NT4+
      MessageBox mb_iconstop "Administrator permission needed!"
      SetErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
      Quit
  ${EndIf}

FunctionEnd

Function un.onInit
  UserInfo::GetAccountType
  pop $0
  ${If} $0 != "admin" ;Require admin rights on NT4+
      MessageBox mb_iconstop "Administrator permission needed!"
      SetErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
      Quit
  ${EndIf}
FunctionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Lucterios2"
  DeleteRegKey HKLM Software\Lucterios2

  ; Remove shortcuts, if any
  Delete "$DESKTOP\@@NAME@@.lnk"

  ; Remove start menu
  RMDir /r "$SMPROGRAMS\@@NAME@@"

  ; Remove directories used
  RMDir /r "$INSTDIR"

SectionEnd
