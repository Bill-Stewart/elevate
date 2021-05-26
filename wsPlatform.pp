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

unit wsPlatform;

interface

function OperatingSystemValid(): Boolean;

implementation

uses
  Windows;

function OperatingSystemValid(): Boolean;
var
  VersionInfo: OSVERSIONINFO;
begin
  result := false;
  VersionInfo.dwOSVersionInfoSize := SizeOf(OSVERSIONINFO);
  if GetVersionEx(VersionInfo) then
    result := (VersionInfo.dwPlatformId = VER_PLATFORM_WIN32_NT) and (VersionInfo.dwMajorVersion > 4);
end;

begin
end.
