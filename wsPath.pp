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

unit wsPath;

interface

function GetSystemDir(): UnicodeString;

function DirExists(const DirName: UnicodeString): Boolean;

implementation

uses
  Windows;

const
  INVALID_FILE_ATTRIBUTES = DWORD(-1);

function GetSystemDir(): UnicodeString;
var
  BufSize: UINT;
  pName: PWideChar;
begin
  result := '';
  BufSize := GetSystemDirectoryW(nil,  // LPWSTR lpBuffer
    0);                                // UINT   uSize
  if BufSize > 0 then
  begin
    BufSize := BufSize * SizeOf(WideChar);
    GetMem(pName, BufSize);
    if GetSystemDirectoryW(pName,  // LPWSTR lpBuffer
      BufSize) > 0 then            // UINT   uSize
      result := pName;
    FreeMem(pName, BufSize);
  end;
end;

function DirExists(const DirName: UnicodeString): Boolean;
var
  Attrs: DWORD;
begin
  Attrs := GetFileAttributesW(PWideChar(DirName));  // LPCWSTR lpFileName
  result := (Attrs <> INVALID_FILE_ATTRIBUTES) and
    ((Attrs and FILE_ATTRIBUTE_DIRECTORY) <> 0);
end;

begin
end.
