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

unit wsPath;

{$MODE OBJFPC}
{$MODESWITCH UNICODESTRINGS}

interface

function GetSystemDir(): string;

function DirExists(const DirName: string): Boolean;

implementation

uses
  windows;

const
  INVALID_FILE_ATTRIBUTES = DWORD(-1);

function GetSystemDir(): string;
var
  BufSize: UINT;
  pName: PChar;
begin
  result := '';
  BufSize := GetSystemDirectoryW(nil,  // LPWSTR lpBuffer
    0);                                // UINT   uSize
  if BufSize > 0 then
  begin
    BufSize := BufSize * SizeOf(Char);
    GetMem(pName, BufSize);
    if GetSystemDirectoryW(pName,  // LPWSTR lpBuffer
      BufSize) > 0 then            // UINT   uSize
      result := pName;
    FreeMem(pName);
  end;
end;

function DirExists(const DirName: string): Boolean;
var
  Attrs: DWORD;
begin
  Attrs := GetFileAttributesW(PChar(DirName));  // LPCWSTR lpFileName
  result := (Attrs <> INVALID_FILE_ATTRIBUTES) and
    ((Attrs and FILE_ATTRIBUTE_DIRECTORY) <> 0);
end;

begin
end.
