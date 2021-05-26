# elevate

**elevate** is a Windows utility that allows you to 1) run a program elevated and 2) test whether the current process is elevated.

## Author

Bill Stewart - bstewart at iname dot com

## License

**elevate** is covered by the GNU Public License (GPL). See the file `LICENSE` for details.

## Download

https://github.com/Bill-Stewart/elevate/releases/

## Usage

Note that in the usage descriptions below, all parameters are case-sensitive.

### Usage 1

**elevate** [**-n**] [**-q**] [**-w** _style_] **--** _command_ [_params_ [...]]

Parameter      | Long Form                 | Description
---------      | ---------                 | -----------
**-n**         | **--nowait**              | Don't wait for program to terminate
**-q**         | **--quiet**               | Run quietly (no dialog boxes)
**-w** _style_ | **--windowstyle=**_style_ | Specifies the window style

_style_ is one of: **Normal** **NormalNotActive** **Minimized** **MinimizedNotActive** **Maximized** **Hidden**

Place all parameters at the start of the command line, in any order, followed by two dashes (**--**). The **--** indicates that what follows it is a command line. If you don't need any of the above parameters, it is still a good idea to use **--** before the command line to prevent command line parsing errors.

Everything after **--** is a command line you want to run elevated. If the current process is not elevated, you will receive a User Account Control (UAC) prompt to run the command. The working directory for the elevated command is always the OS `System32` directory.

Without **-n** (**--nowait**), the exit code will be the exit code of the program. If the user cancels the elevation prompt, the exit code will be 1223.

### Usage 2

**elevate** [**-q**] **-t**

Parameter | Long Form   | Description
--------- | ---------   | ------------
**-q**    | **--quiet** | Run quietly (no dialog boxes)
**-t**    | **--test**  | Test if current process is elevated

With **-t** (**--test**), the exit code will be 0 if the current process is not elevated, or 1 if the current process is elevated.

