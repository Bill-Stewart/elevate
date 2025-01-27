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

program elevate;

{$MODE OBJFPC}
{$MODESWITCH UNICODESTRINGS}

{$IFNDEF DEBUG}
{$APPTYPE GUI}
{$ENDIF}
{$R *.res}

// wargcv/wgetopts: https://github.com/Bill-Stewart/wargcv
// WindowsString: https://github.com/Bill-Stewart/WindowsString
uses
  windows,
  wargcv,
  wgetopts,
  wsProcess,
  WindowsString;

const
  APP_TITLE = 'elevate';
  ERROR_PARAMETER_MISSING = 3052;

type
  TCommandLine = object
    ErrorCode: DWORD;
    ErrorMessage: string;
    Help: Boolean;
    Quiet: Boolean;
    Test: Boolean;
    Wait: Boolean;
    WindowStyle: TWindowStyle;
    WorkingDirectory, Executable, Parameters: string;
    procedure Parse();
  end;

procedure Usage();
var
  Msg: string;
begin
  Msg := APP_TITLE + ' - Copyright (C) 2021-2025 by Bill Stewart (bstewart at iname.com)' + sLineBreak
    + 'This is free software and comes with ABSOLUTELY NO WARRANTY.' + sLineBreak
    + sLineBreak
    + 'Usage 1:' + #9 + 'elevate [-n] [-q] [-w <style>] [-W dir] -- command [params [...]]' + sLineBreak
    + sLineBreak
    + '-n' + #9 + '(--nowait) Don''t wait for program to terminate' + sLineBreak
    + '-q' + #9 + '(--quiet) Run quietly (no dialog boxes)' + sLineBreak
    + '-w' + #9 + '(--windowstyle <style>) Specifies the window style' + sLineBreak
    + '-W' + #9 + '(--workingdir) Specifies a working directory' + sLineBreak
    + sLineBreak
    + '<style> is one of: Normal NormalNotActive Minimized MinimizedNotActive Maximized Hidden' + sLineBreak
    + sLineBreak
    + 'Everything after -- is a command line you want to run elevated. If the '
    + 'current process is not elevated, you will receive a User Account '
    + 'Control (UAC) prompt to run the command. The working directory for the '
    + 'elevated command is always the System32 directory.' + sLineBreak
    + sLineBreak
    + 'Without -n (--nowait), the exit code will be the exit code of the ' +
    'program. If the user cancels the elevation prompt, the exit code will ' +
    'be 1223.' + sLineBreak
    + sLineBreak
    + 'Usage 2:' + #9 + 'elevate [-q] -t' + sLineBreak
    + sLineBreak
    + '-q' + #9 + '(--quiet) Run quietly (no dialog boxes)' + sLineBreak
    + '-t' + #9 + '(--test) Test if current process is elevated' + sLineBreak
    + sLineBreak
    + 'With -t (--test), the exit code will be 0 if the current process is '
    + 'not elevated, or 1 if the current process is elevated.';

  MessageBoxW(0,  // HWND    hWnd
    PChar(Msg),   // LPCWSTR lpText
    APP_TITLE,    // LPCWSTR lpCaption
    0);           // UINT    uType
end;

function DirExists(const DirName: string): Boolean;
const
  INVALID_FILE_ATTRIBUTES = DWORD(-1);
var
  Attrs: DWORD;
begin
  Attrs := GetFileAttributesW(PChar(DirName));  // LPCWSTR lpFileName
  result := (Attrs <> INVALID_FILE_ATTRIBUTES) and
    ((Attrs and FILE_ATTRIBUTE_DIRECTORY) <> 0);
end;

procedure TCommandLine.Parse();
var
  LongOpts: array[1..7] of TOption;
  Opt: Char;
  I: Integer;
begin
  with LongOpts[1] do
  begin
    Name := 'help';
    Has_arg := No_Argument;
    Flag := nil;
    Value := 'h';
  end;
  with LongOpts[2] do
  begin
    Name := 'nowait';
    Has_arg := No_Argument;
    Flag := nil;
    Value := 'n';
  end;
  with LongOpts[3] do
  begin
    Name := 'quiet';
    Has_arg := No_Argument;
    Flag := nil;
    Value := 'q';
  end;
  with LongOpts[4] do
  begin
    Name := 'test';
    Has_arg := No_Argument;
    Flag := nil;
    Value := 't';
  end;
  with LongOpts[5] do
  begin
    Name := 'windowstyle';
    Has_arg := Required_Argument;
    Flag := nil;
    Value := 'w';
  end;
  with LongOpts[6] do
  begin
    Name    := 'workingdir';
    Has_arg := Required_Argument;
    Flag    := nil;
    Value   := 'W';
  end;
  with LongOpts[7] do
  begin
    Name := '';
    Has_arg := No_Argument;
    Flag := nil;
    Value := #0;
  end;
  ErrorCode := 0;
  ErrorMessage := '';
  Help := false;
  Quiet := false;
  Test := false;
  Wait := true;
  WindowStyle := Normal;
  WorkingDirectory := '';
  Executable := '';
  Parameters := '';
  OptErr := false;  // no error output from GetOpts
  repeat
    Opt := GetLongOpts('hnqtw:W:', @LongOpts, I);
    case Opt of
      'h': Help := true;
      'n': Wait := false;
      'q': Quiet := true;
      't': Test := true;
      'w':
      begin
        case LowercaseString(OptArg) of
          'hidden': WindowStyle := Hidden;
          'normal': WindowStyle := Normal;
          'minimized': WindowStyle := Minimized;
          'maximized': WindowStyle := Maximized;
          'normalnotactive': WindowStyle := NormalNotActive;
          'minimizednotactive': WindowStyle := MinimizedNotActive;
          else
          begin
            ErrorCode := ERROR_INVALID_PARAMETER;
            ErrorMessage := '--windowstyle (-w) must specify one of the following: ' +
              'Normal NormalNotActive Minimized MinimizedNotActive Maximized Hidden';
          end;
        end;
      end;
      'W':
        begin
          if OptArg = '' then
          begin
            ErrorCode := ERROR_INVALID_PARAMETER;
            ErrorMessage := '-W requires an argument';
          end
          else
          begin
            WorkingDirectory := OptArg;
            if not DirExists(WorkingDirectory) then
            begin
              ErrorCode := ERROR_PATH_NOT_FOUND;
              ErrorMessage := 'Directory not found - ' + WorkingDirectory;
            end;
          end;
        end;
      '?':
      begin
        ErrorCode := ERROR_INVALID_PARAMETER;
        ErrorMessage := 'Invalid parameter specified; use --help (-h) for usage information';
      end;
    end;
  until Opt = EndOfOptions;
  if not Test then
  begin
    Executable := ParamStr(OptInd);
    if Executable = '' then
      ErrorCode := ERROR_PARAMETER_MISSING
    else
      Parameters := GetCommandTail(GetCommandLineW(), OptInd + 1);
  end;
end;

function GetElevationString(const Elevated: Boolean): string;
begin
  if Elevated then
    result := 'The current process is elevated.'
  else
    result := 'The current process is not elevated.';
end;

procedure InfoDlg(const Msg: string);
begin
  MessageBoxW(0,          // HWND    hWnd
    PChar(Msg),           // LPCWSTR lpText
    APP_TITLE,            // LPCWSTR lpCaption
    MB_ICONINFORMATION);  // UINT    uType
end;

procedure ErrorDlg(const Msg: string; const ErrCode: DWORD);
var
  S: string;
begin
  Str(ErrCode, S);
  MessageBoxW(0,                  // HWND    hWnd
    PChar(Msg + ' (' + S + ')'),  // LPCWSTR lpText
    APP_TITLE,                    // LPCWSTR lpCaption
    MB_ICONERROR);                // UINT    uType
end;

function IsOSNewEnough(): Boolean;
var
  VersionInfo: OSVERSIONINFO;
begin
  result := false;
  VersionInfo.dwOSVersionInfoSize := SizeOf(OSVERSIONINFO);
  if GetVersionEx(VersionInfo) then
    result := (VersionInfo.dwPlatformId = VER_PLATFORM_WIN32_NT)
      and (VersionInfo.dwMajorVersion > 4);
end;

var
  CommandLine: TCommandLine;  // Command line parser object
  ResultCode: DWORD;
  Elevated: Boolean;

begin
  if not IsOSNewEnough() then
  begin
    ResultCode := ERROR_OLD_WIN_VERSION;
    ErrorDlg('This program requires Windows 2000 or later.', ResultCode);
    ExitCode := Integer(ResultCode);
    exit;
  end;

  if ParamStr(1) = '/?' then
  begin
    Usage();
    exit;
  end;

  CommandLine.Parse();
  if CommandLine.Help then
  begin
    Usage();
    exit;
  end;

  // Fail if we got a command-line error
  if CommandLine.ErrorCode <> ERROR_SUCCESS then
  begin
    if CommandLine.ErrorCode = ERROR_PARAMETER_MISSING then
      Usage()
    else if not CommandLine.Quiet then
      ErrorDlg(CommandLine.ErrorMessage, CommandLine.ErrorCode);
    ExitCode := Integer(CommandLine.ErrorCode);
    exit;
  end;

  if CommandLine.Test then
  begin
    ResultCode := IsElevated(Elevated);
    if ResultCode = 0 then
    begin
      if Elevated then
        ExitCode := 1
      else
        ExitCode := 0;
      if not CommandLine.Quiet then
        InfoDlg(GetElevationString(Elevated));
    end
    else
    begin
      if not CommandLine.Quiet then
        ErrorDlg('Windows API error occurred.', ResultCode);
      ExitCode := Integer(ResultCode);
    end;
    exit;
  end;

  {$IFDEF DEBUG}
  WriteLn('Quiet: ', CommandLine.Quiet);
  WriteLn('Wait: ', CommandLine.Wait);
  WriteLn('WindowStyle: ', Integer(CommandLine.WindowStyle));
  WriteLn('WorkingDirectory: ', CommandLine.WorkingDirectory);
  WriteLn('Executable: ', CommandLine.Executable);
  WriteLn('Parameters: ', CommandLine.Parameters);
  {$ENDIF}
  ShellExec(CommandLine.Executable,  // Executable
    CommandLine.Parameters,          // Parameters
    CommandLine.WorkingDirectory,    // WorkingDirectory
    CommandLine.WindowStyle,         // WindowStyle
    CommandLine.Wait,                // Wait
    CommandLine.Quiet,               // Quiet
    true,                            // Elevate
    ResultCode);                     // ResultCode
  ExitCode := Integer(ResultCode);
  {$IFDEF DEBUG}
  WriteLn('Result code: ', ResultCode);
  WriteLn('Exit code: ', ExitCode);
  {$ENDIF}
end.
