; Compile the published Native AOT executable directly; no DLL sidecars are required.
#ifndef AppVersion
  #error AppVersion must be supplied with /DAppVersion
#endif
#ifndef PublishDir
  #define PublishDir "..\..\dist"
#endif
#ifndef InstallerOutputDir
  #define InstallerOutputDir "Deploy\OUT"
#endif

[Setup]
AppId=cc.tiouoo.Pollen
AppName=Pollen
AppVersion={#AppVersion}
VersionInfoVersion={#AppVersion}
AppPublisher=github.com/tiouoo/Pollen
AppPublisherURL=https://github.com/tiouoo/Pollen
AppCopyright=Copyright (C) Pollen 2026
LicenseFile=..\..\LICENSE
SetupIconFile=..\icon-pattern.ico
DefaultDirName={autopf}\Pollen.Desktop
DefaultGroupName=Pollen
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10
AllowNoIcons=yes
DisableDirPage=yes
OutputDir={#InstallerOutputDir}
OutputBaseFilename=Pollen.win.x64.installer
Compression=lzma2
SolidCompression=yes
UninstallDisplayIcon={app}\Pollen.Desktop.exe

[Languages]
Name: "chinesesimplified"; MessagesFile: "ChineseSimplified.isl"

[Files]
Source: "{#PublishDir}\Pollen.Desktop.exe"; DestDir: "{app}"; Flags: ignoreversion

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Icons]
Name: "{group}\Pollen"; Filename: "{app}\Pollen.Desktop.exe"
Name: "{userdesktop}\Pollen"; Filename: "{app}\Pollen.Desktop.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\Pollen.Desktop.exe"; Description: "{cm:LaunchProgram,Pollen}"; Flags: postinstall nowait skipifsilent
