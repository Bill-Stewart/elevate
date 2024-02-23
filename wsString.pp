{ Copyright (C) 2021-2024 by Bill Stewart (bstewart at iname.com)

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

unit wsString;

{$MODE OBJFPC}
{$MODESWITCH UNICODESTRINGS}

interface

function LowercaseString(const S: string): string;

implementation

uses
  windows;

function LowercaseString(const S: string): string;
var
  Locale: LCID;
  Len: DWORD;
  pResult: PChar;
begin
  result := '';
  if S = '' then
    exit;
  Locale := MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT);
  Len := LCMapStringW(Locale,  // LCID    Locale
    LCMAP_LOWERCASE,           // DWORD   dwMapFlags
    PChar(S),                  // LPCWSTR lpSrcStr
    -1,                        // int     cchSrc
    nil,                       // LPWSTR  lpDestStr
    0);                        // int     cchDest
  if Len = 0 then
    exit;
  GetMem(pResult, Len * SizeOf(Char));
  if LCMapStringW(Locale,  // LCID    Locale
    LCMAP_LOWERCASE,       // DWORD   dwMapFlags
    PChar(S),              // LPCWSTR lpSrcStr
    -1,                    // int     cchSrc
    pResult,               // LPWSTR  lpDestStr
    Len) > 0 then          // int     cchDest
  begin
    result := string(pResult);
  end;
  FreeMem(pResult);
end;

begin
end.
