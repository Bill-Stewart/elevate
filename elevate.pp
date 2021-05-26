program elevate;

{$MODE OBJFPC}
{$H+}
{$IFNDEF DEBUG}
{$APPTYPE GUI}
{$ENDIF}
{$R *.res}

uses
  getopts,
  Windows,
  wsPath,
  wsPlatform,
  wsProcess,
  wsString;

const
  APP_TITLE               = 'elevate';
  ERROR_PARAMETER_MISSING = 3052;

type
  TCommandLine = object
    ErrorCode:              LongInt;
    ErrorMessage:           UnicodeString;
    Help:                   Boolean;
    Quiet:                  Boolean;
    Test:                   Boolean;
    Wait:                   Boolean;
    WindowStyle:            TWindowStyle;
    WorkingDirectory:       UnicodeString;
    Executable, Parameters: UnicodeString;
    procedure Parse();
  end;

procedure Usage();
var
  Msg: UnicodeString;
begin
  Msg := 'elevate - Copyright (C) 2021 by Bill Stewart (bstewart at iname.com)' + #10
    + 'This is free software and comes with ABSOLUTELY NO WARRANTY.' + #10
    + #10
    + 'Usage 1:' + #9 + 'elevate [-d] [-q] [-w <style>] -- command [params [...]]' + #10
    + #10
    + '-n' + #9 + '(--nowait) Don''t wait for program to terminate' + #10
    + '-q' + #9 + '(--quiet) Run quietly (no dialog boxes)' + #10
    + '-w' + #9 + '(--windowstyle=<style>) Specifies the window style' + #10
  //+ '-W' + #9 + '(--workingdir) Specifies a working directory' + #10
    + #10
    + '<style> is one of: Normal NormalNotActive Minimized MinimizedNotActive Maximized Hidden' + #10
    + #10
    + 'Everything after -- is a command line you want to run elevated. If the '
    + 'current process is not elevated, you will receive a User Account Control '
    + '(UAC) prompt to run the command. The working directory for the elevated '
    + 'command is always the System32 directory.' + #10
    + #10
    + 'Without -n (--nowait), the exit code will be the exit code of the '
    + 'program. If the user cancels the elevation prompt, the exit code will '
    + 'be 1223.' + #10
    + #10
    + 'Usage 2:' + #9 + 'elevate [-q] -t' + #10
    + #10
    + '-q' + #9 + '(--quiet) Run quietly (no dialog boxes)' + #10
    + '-t' + #9 + '(--test) Test if current process is elevated' + #10
    + #10
    + 'With -t (--test), the exit code will be 0 if the current process is not '
    + 'elevated, or 1 if the current process is elevated.';
  MessageBoxW(0,     // HWND    hWnd
    PWideChar(Msg),  // LPCWSTR lpText
    APP_TITLE,       // LPCWSTR lpCaption
    0);              // UINT    uType
end;

procedure TCommandLine.Parse();
var
  LongOpts: array[1..6] of TOption;
  Opt: Char;
  I: LongInt;
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
  //with LongOpts[n] do
  //begin
  //  Name    := 'workingdir';
  //  Has_arg := Required_Argument;
  //  Flag    := nil;
  //  Value   := 'W';
  //end;
  with LongOpts[6] do
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
    Opt := GetLongOpts('hnqtw:', @LongOpts, I);
    case Opt of
      'h': Help := true;
      'n': Wait := false;
      'q': Quiet := true;
      't': Test := true;
      'w':
      begin
        case Lowercase(OptArg) of
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
        end; //case Lowercase(OptArg)
      end;
      // Working directory ignored when elevating
      //'W':
      //  begin
      //    if OptArg = '' then
      //    begin
      //      ErrorCode    := ERROR_INVALID_PARAMETER;
      //      ErrorMessage := '-W requires an argument';
      //    end
      //    else
      //    begin
      //      WorkingDirectory := StringToUnicodeString(OptArg);
      //      if not DirExists(WorkingDirectory) then
      //      begin
      //        ErrorCode    := ERROR_PATH_NOT_FOUND;
      //        ErrorMessage := 'Directory not found - ' + WorkingDirectory;
      //      end;
      //    end;
      //  end;
      '?':
      begin
        ErrorCode := ERROR_INVALID_PARAMETER;
        ErrorMessage := 'Invalid parameter specified; use --help (-h) for usage information';
      end;
    end; //case Opt
  until Opt = EndOfOptions;
  if not Test then
  begin
    Executable := StringToUnicodeString(ParamStr(OptInd));
    if Executable = '' then
      ErrorCode := ERROR_PARAMETER_MISSING
    else
      Parameters := GetCommandTail(OptInd + 1);
  end;
end;

function GetElevationString(const Elevated: Boolean): UnicodeString;
begin
  if Elevated then
    result := 'The current process is elevated'
  else
    result := 'The current process is not elevated';
end;

procedure InfoDlg(const Msg: UnicodeString);
begin
  MessageBoxW(0,          // HWND    hWnd
    PWideChar(Msg),       // LPCWSTR lpText
    APP_TITLE,            // LPCWSTR lpCaption
    MB_ICONINFORMATION);  // UINT    uType
end;

procedure ErrorDlg(const Msg: UnicodeString; const ErrCode: Word);
var
  S: UnicodeString;
begin
  Str(ErrCode, S);
  MessageBoxW(0,                      // HWND    hWnd
    PWideChar(Msg + ' (' + S + ')'),  // LPCWSTR lpText
    APP_TITLE,                        // LPCWSTR lpCaption
    MB_ICONERROR);                    // UINT    uType
end;

var
  CommandLine: TCommandLine;  // Command line parser object
  ResultCode: DWORD;
  Elevated: Boolean;

begin
  if not OperatingSystemValid() then
  begin
    ExitCode := ERROR_OLD_WIN_VERSION;
    ErrorDlg('This program requires Windows 2000 or later.', ExitCode);
    exit();
  end;

  if ParamStr(1) = '/?' then
  begin
    Usage();
    exit();
  end;

  CommandLine.Parse();
  if CommandLine.Help then
  begin
    Usage();
    exit();
  end;

  // Fail if we got a command-line error
  ExitCode := CommandLine.ErrorCode;
  if ExitCode <> 0 then
  begin
    if ExitCode = ERROR_PARAMETER_MISSING then
      Usage()
    else if not CommandLine.Quiet then
      ErrorDlg(CommandLine.ErrorMessage, CommandLine.ErrorCode);
    exit();
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
      ExitCode := LongInt(ResultCode);
      if not CommandLine.Quiet then
        ErrorDlg('Windows API error occurred.', ResultCode);
    end;
    exit();
  end;

  // This is the usual case when elevating
  CommandLine.WorkingDirectory := GetSystemDir();

  {$IFDEF DEBUG}
  WriteLn('Quiet: ', CommandLine.Quiet);
  WriteLn('Wait: ', CommandLine.Wait);
  WriteLn('WindowStyle: ', Integer(CommandLine.WindowStyle));
  //WriteLn('WorkingDirectory: ', CommandLine.WorkingDirectory);
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
  ExitCode := LongInt(ResultCode);
  {$IFDEF DEBUG}
  WriteLn('Result code: ', ResultCode);
  WriteLn('Exit code: ', ExitCode);
  {$ENDIF}
end.
