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

unit wsString;

interface

function StringToUnicodeString(const S: string): UnicodeString;

function UnicodeStringToString(const S: UnicodeString): string;

implementation

uses
  Windows;

function StringToUnicodeString(const S: string): UnicodeString;
var
  NumChars, BufSize: DWORD;
  pBuffer: PWideChar;
begin
  result := '';
  NumChars := MultiByteToWideChar(CP_OEMCP,  // UINT   CodePage
    0,                                       // DWORD  dwFlags
    PChar(S),                                // LPCCH  lpMultiByteStr
    -1,                                      // int    cbMultiByte
    nil,                                     // LPWSTR lpWideCharStr
    0);                                      // int    cchWideChar
  if NumChars > 0 then
  begin
    BufSize := NumChars * SizeOf(WideChar);
    GetMem(pBuffer, BufSize);
    if MultiByteToWideChar(CP_OEMCP,  // UINT   CodePage
      0,                              // DWORD  dwFlags
      PChar(S),                       // LPCCH  lpMultiByteStr
      -1,                             // int    cbMultiByte
      pBuffer,                        // LPWSTR lpWideCharStr
      NumChars) > 0 then              // int    cchWideChar
      result := UnicodeString(pBuffer);
    FreeMem(pBuffer, BufSize);
  end;
end;

function UnicodeStringToString(const S: UnicodeString): string;
var
  NumChars, BufSize: DWORD;
  pBuffer: PChar;
begin
  result := '';
  NumChars := WideCharToMultiByte(CP_OEMCP,  // UINT   CodePage
    0,                                       // DWORD  dwFlags
    PWideChar(S),                            // LPCWCH lpWideCharStr
    -1,                                      // int    cchWideChar
    nil,                                     // LPSTR  lpMultiByteStr
    0,                                       // int    cbMultiByte
    nil,                                     // LPCCH  lpDefaultChar
    nil);                                    // LPBOOL lpUsedDefaultChar
  if NumChars > 0 then
  begin
    BufSize := NumChars * SizeOf(Char);
    GetMem(pBuffer, BufSize);
    if WideCharToMultiByte(CP_OEMCP,  // UINT   CodePage
      0,                              // DWORD  dwFlags
      PWideChar(S),                   // LPCWCH lpWideCharStr
      -1,                             // int    cchWideChar
      pBuffer,                        // LPSTR  lpMultiByteStr
      NumChars,                       // int    cbMultiByte
      nil,                            // LPCCH  lpDefaultChar
      nil) > 0 then                   // LPBOOL lpUsedDefaultChar
      result := string(pBuffer);
    FreeMem(pBuffer, BufSize);
  end;
end;

begin
end.
