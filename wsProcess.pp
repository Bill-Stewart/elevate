{ Copyright (C) 2021 by Bill Stewart (bstewart at iname.com)

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

{$MODE OBJFPC}
{$H+}

unit wsProcess;

interface

uses
  Windows;

type
  TWindowStyle = (Hidden             = SW_HIDE,
                  Normal             = SW_SHOWNORMAL,
                  Minimized          = SW_SHOWMINIMIZED,
                  Maximized          = SW_SHOWMAXIMIZED,
                  NormalNotActive    = SW_SHOWNOACTIVATE,
                  MinimizedNotActive = SW_SHOWMINNOACTIVE);

// Gets the (unparsed) content of the command line starting at the specified
// parameter.
function GetCommandTail(const StartParam: LongInt): UnicodeString;

// Returns 0 if all APIs executed successfully. If any API failed, returns the
// error code of the API that failed. If the function returns 0, then Elevated
// will be true if the current process is elevated, or false otherwise.
function IsElevated(var Elevated: Boolean): DWORD;

// Runs an executable using the ShellExecuteExW API. Returns true if all APIs
// executed successfully, or false if any APIs failed. If the function returns
// false, then ResultCode will contain the error code returned by the API that
// failed. If the function returns true, then the value in ResultCode will be 0 
// if Wait is false or the program's exit code if Wait is true.
function ShellExec(const Executable, Parameters, WorkingDirectory: UnicodeString;
  const WindowStyle: TWindowStyle; const Wait, Quiet, Elevate: Boolean; var ResultCode: DWORD): Boolean;

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

function CheckTokenMembership(TokenHandle: HANDLE; SidToCheck: PSID; var IsMember: Boolean): BOOL; stdcall;
  external 'advapi32.dll';

function ShellExecuteExW(var ShellExecuteInfo: TShellExecuteInfo): BOOL; stdcall;
  external 'shell32.dll';

// See MSDN API sample for CheckTokenMembership function
function IsElevated(var Elevated: Boolean): DWORD;
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
      result := ERROR_SUCCESS
    else
      result := GetLastError();
    FreeSid(pSidLocalAdministratorsGroup);  // PSID pSid
  end
  else
    result := GetLastError();
end;

function GetCommandTail(const StartParam: LongInt): UnicodeString;
const
  WHITESPACE: set of Char = [#9, #32];
var
  pCL, pTail: PWideChar;
  InQuote: Boolean;
  ParamNum, I: LongInt;
begin
  pCL := GetCommandLineW();
  pTail := nil;
  if pCL^ <> #0 then
  begin
    while pCL^ in WHITESPACE do  // Skip leading whitespace
      Inc(pCL);
    InQuote := false;
    pTail := pCL;
    ParamNum := 0;
    for I := 0 to Length(pCL) do
    begin
      case pCL[I] of
        #0:
          break;
        '"':
        begin
          InQuote := not InQuote;
          if InQuote then
          begin
            if ParamNum = StartParam then
              break;
          end;
          Inc(pTail);
        end;
        #1..#32:
        begin
          if (not InQuote) and (not (pCL[I - 1] in WHITESPACE)) then
            Inc(ParamNum);
          Inc(pTail);
        end;
      else
        begin
          if ParamNum = StartParam then
            break
          else
            Inc(pTail);
        end;
      end; //case
    end;
  end;
  result := pTail;
end;

function ShellExec(const Executable, Parameters, WorkingDirectory: UnicodeString;
  const WindowStyle: TWindowStyle; const Wait, Quiet, Elevate: Boolean; var ResultCode: DWORD): Boolean;
var
  ShellExecuteInfo: TShellExecuteInfo;
begin
  FillChar(ShellExecuteInfo, SizeOf(ShellExecuteInfo), 0);
  ShellExecuteInfo.cbSize := SizeOf(ShellExecuteInfo);
  if Wait then
    ShellExecuteInfo.fMask := ShellExecuteInfo.fMask or SEE_MASK_NOCLOSEPROCESS;
  if Quiet then
    ShellExecuteInfo.fMask := ShellExecuteInfo.fMask or SEE_MASK_FLAG_NO_UI;
  if Elevate then
    ShellExecuteInfo.lpVerb := 'runas'
  else
    ShellExecuteInfo.lpVerb := 'open';
  ShellExecuteInfo.lpFile := PWideChar(Executable);
  if Parameters <> '' then
    ShellExecuteInfo.lpParameters := PWideChar(Parameters)
  else
    ShellExecuteInfo.lpParameters := nil;
  if WorkingDirectory <> '' then
    ShellExecuteInfo.lpDirectory := PWideChar(WorkingDirectory)
  else
    ShellExecuteInfo.lpDirectory := nil;
  ShellExecuteInfo.nShow := Integer(WindowStyle);
  result := ShellExecuteExW(ShellExecuteInfo);
  if result then
  begin
    if Wait then
    begin
      result := WaitForSingleObject(ShellExecuteInfo.hProcess,  // HANDLE hHandle
        INFINITE) <> WAIT_FAILED;                               // DWORD  dwMilliseconds
      if result then
      begin
        result := GetExitCodeProcess(ShellExecuteInfo.hProcess,  // HANDLE  hProcess
          ResultCode);                                           // LPDWORD lpExitCode
        if not result then
          ResultCode := GetLastError();
      end
      else
        ResultCode := GetLastError();
    end
    else
      ResultCode := 0;
    CloseHandle(ShellExecuteInfo.hProcess);  // HANDLE hObject
  end
  else
    ResultCode := GetLastError();
end;

begin
end.
