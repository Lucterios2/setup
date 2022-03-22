; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "@@NAME@@"
#define MyAppVersion "@@NAME@@ #@@BUILD@@"
#define MyAppPublisher "sd-libre.fr"
#define MyAppURL "https://www.sd-libre.fr"
#define INSTDIR "c:\lucterios2"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{361A7CAF-D8AD-4A22-ADF7-4E8FA47C97CA}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
PrivilegesRequired=admin
DefaultDirName={#INSTDIR}
DisableDirPage=yes
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=License.txt
OutputDir=.\
OutputBaseFilename={#MyAppName}_setup
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Files]
Source: "install.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Python\*"; DestDir: "{app}\Python"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Run]
Filename: "PowerShell.exe"; Flags: waituntilterminated; Parameters: "-ExecutionPolicy Bypass -File ""{#INSTDIR}\install.ps1"" "
Filename: {#INSTDIR}\{#MyAppName}.lnk; Flags: shellexec skipifsilent nowait; Tasks: StartAfterInstall

[Tasks]
Name: StartLoginWindows; Description: "Demarrer automatiquement avec Windows"; GroupDescription: "Fin d'installation"; Flags: unchecked
Name: StartAfterInstall; Description: "Lancer l'application en fin d'installation"; GroupDescription: "Fin d'installation"

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
var
    ResultCode: Integer;
begin
    if CurStep = ssDone then 
    begin
      FileCopy(ExpandConstant('{#INSTDIR}\{#MyAppName}.lnk'), ExpandConstant('{commondesktop}\{#MyAppName}.lnk'), False);
      FileCopy(ExpandConstant('{#INSTDIR}\{#MyAppName}.lnk'), ExpandConstant('{group}\{#MyAppName}.lnk'), False);
    end;
end;

[Icons]
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{userstartup}\{#MyAppName}"; Filename: "{#INSTDIR}\{#MyAppName}.lnk; WorkingDir: "{#INSTDIR}"; Tasks: StartLoginWindows 

