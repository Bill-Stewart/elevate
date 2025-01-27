{ Copyright (C) 2021-2025 by Bill Stewart (bstewart at iname.com)

  This program is free software: you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free Software
  Foundation, either version 3 of the License, or (at your option) any later
  version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
  details.

  You should have received a copy of the GNU General Public License
  along with this program. If not, see https://www.gnu.org/licenses/.

}

unit wsProcess;

{$MODE OBJFPC}
{$MODESWITCH UNICODESTRINGS}

interface

uses
  windows;

type
  TWindowStyle = (
    Hidden             = SW_HIDE,
    Normal             = SW_SHOWNORMAL,
    Minimized          = SW_SHOWMINIMIZED,
    Maximized          = SW_SHOWMAXIMIZED,
    NormalNotActive    = SW_SHOWNOACTIVATE,
    MinimizedNotActive = SW_SHOWMINNOACTIVE);

// Returns 0 if all APIs executed successfully. If any API failed, returns the
// error code of the API that failed. If the function returns 0, then Elevated
// will be true if the current process is elevated, or false otherwise.
function IsElevated(out Elevated: Boolean): DWORD;

// Runs an executable using the ShellExecuteExW API. Returns true if all APIs
// executed successfully, or false if any APIs failed. If the function returns
// false, then ResultCode will contain the error code returned by the API that
// failed. If the function returns true, then the value in ResultCode will be 0 
// if Wait is false or the program's exit code if Wait is true.
function ShellExec(const Executable, Parameters, WorkingDirectory: string;
  const WindowStyle: TWindowStyle; const Wait, Quiet, Elevate: Boolean;
  out ResultCode: DWORD): Boolean;

implementation

const
  SEE_MASK_DEFAULT           = $00000000;
  SEE_MASK_CLASSNAME         = $00000001;
  SEE_MASK_CLASSKEY          = $00000003;
  SEE_MASK_IDLIST            = $00000004;
  SEE_MASK_INVOKEIDLIST      = $0000000C;
  SEE_MASK_ICON              = $00000010;
  SEE_MASK_HOTKEY            = $00000020;
  SEE_MASK_NOCLOSEPROCESS    = $00000040;
  SEE_MASK_CONNECTNETDRV     = $00000080;
  SEE_MASK_NOASYNC           = $00000100;
  SEE_MASK_FLAG_DDEWAIT      = $00000100;
  SEE_MASK_DOENVSUBST        = $00000200;
  SEE_MASK_FLAG_NO_UI        = $00000400;
  SEE_MASK_UNICODE           = $00004000;
  SEE_MASK_NO_CONSOLE        = $00008000;
  SEE_MASK_ASYNCOK           = $00100000;
  SEE_MASK_NOQUERYCLASSSTORE = $01000000;
  SEE_MASK_HMONITOR          = $00200000;
  SEE_MASK_NOZONECHECKS      = $00800000;
  SEE_MASK_WAITFORINPUTIDLE  = $02000000;
  SEE_MASK_FLAG_LOG_USAGE    = $04000000;

type
  TShellExecuteInfo = record
    cbSize:       DWORD;
    fMask:        ULONG;
    hwnd:         ULONG;
    lpVerb:       LPCWSTR;
    lpFile:       LPCWSTR;
    lpParameters: LPCWSTR;
    lpDirectory:  LPCWSTR;
    nShow:        LongInt;
    hInstApp:     HINST;
    lpIDList:     LPVOID;
    lpClass:      LPCWSTR;
    hKeyClass:    HKEY;
    dwHotKey:     DWORD;
    hMonitor:     HANDLE;
    hProcess:     HANDLE;
  end;

function CheckTokenMembership(TokenHandle: HANDLE;
  SidToCheck: PSID;
  out IsMember: Boolean): BOOL; stdcall;
  external 'advapi32.dll';

function ShellExecuteExW(var ShellExecuteInfo: TShellExecuteInfo): BOOL; stdcall;
  external 'shell32.dll';

// See MSDN API sample for CheckTokenMembership function
function IsElevated(out Elevated: Boolean): DWORD;
const
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
var
  pSidLocalAdministratorsGroup: PSID;
begin
  if AllocateAndInitializeSid(SECURITY_NT_AUTHORITY,  // PSID_IDENTIFIER_AUTHORITY pIdentifierAuthority
    2,                                                // BYTE                      nSubAuthorityCount
    SECURITY_BUILTIN_DOMAIN_RID,                      // DWORD                     nSubAuthority0
    DOMAIN_ALIAS_RID_ADMINS,                          // DWORD                     nSubAuthority1
    0,                                                // DWORD                     nSubAuthority2
    0,                                                // DWORD                     nSubAuthority3
    0,                                                // DWORD                     nSubAuthority4
    0,                                                // DWORD                     nSubAuthority5
    0,                                                // DWORD                     nSubAuthority6
    0,                                                // DWORD                     nSubAuthority7
    pSidLocalAdministratorsGroup) then                // PSID                      *pSid
  begin
    if CheckTokenMembership(0,       // HANDLE TokenHandle
      pSidLocalAdministratorsGroup,  // PSID   SidToCheck
      Elevated) then                 // PBOOL  IsMember
    begin
      result := ERROR_SUCCESS;
    end
    else
      result := GetLastError();
    FreeSid(pSidLocalAdministratorsGroup);  // PSID pSid
  end
  else
    result := GetLastError();
end;

function ShellExec(const Executable, Parameters, WorkingDirectory: string;
  const WindowStyle: TWindowStyle; const Wait, Quiet, Elevate: Boolean;
  out ResultCode: DWORD): Boolean;
var
  SEI: TShellExecuteInfo;
begin
  FillChar(SEI, SizeOf(SEI), 0);
  SEI.cbSize := SizeOf(SEI);
  if Wait then
    SEI.fMask := SEI.fMask or SEE_MASK_NOCLOSEPROCESS;
  if Quiet then
    SEI.fMask := SEI.fMask or SEE_MASK_FLAG_NO_UI;
  if Elevate then
    SEI.lpVerb := 'runas'
  else
    SEI.lpVerb := 'open';
  SEI.lpFile := PChar(Executable);
  if Parameters <> '' then
    SEI.lpParameters := PChar(Parameters)
  else
    SEI.lpParameters := nil;
  if WorkingDirectory <> '' then
    SEI.lpDirectory := PChar(WorkingDirectory)
  else
    SEI.lpDirectory := nil;
  SEI.nShow := Integer(WindowStyle);
  result := ShellExecuteExW(SEI);
  if result then
  begin
    if Wait then
    begin
      result := WaitForSingleObject(SEI.hProcess,  // HANDLE hHandle
        INFINITE) <> WAIT_FAILED;                  // DWORD  dwMilliseconds
      if result then
      begin
        result := GetExitCodeProcess(SEI.hProcess,  // HANDLE  hProcess
          ResultCode);                              // LPDWORD lpExitCode
        if not result then
          ResultCode := GetLastError();
      end
      else
        ResultCode := GetLastError();
    end
    else
      ResultCode := 0;
    CloseHandle(SEI.hProcess);  // HANDLE hObject
  end
  else
    ResultCode := GetLastError();
end;

begin
end.
