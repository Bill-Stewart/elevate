# elevate

**elevate** is a Windows utility that allows you to 1) provoke a UAC prompt to request to run a program elevated and 2) test whether the current process is elevated.

## Author

Bill Stewart - bstewart at iname dot com

## License

**elevate** is covered by the GNU Public License (GPL). See the file `LICENSE` for details.

## Download

https://github.com/Bill-Stewart/elevate/releases/

## Usage

Note that in the usage descriptions below, all parameters are case-sensitive.

### Usage 1

Usage 1 is a command-line equivalent of right-clicking a program in Windows Explorer and choosing the **Run as administator** option. If the current process is not elevated (running as administrator), **elevate** will display a UAC (User Account Control) dialog requesting administrative permissions or administrative credentials, just like the **Run as administrator** option.

> NOTE: The **elevate** utility merely provides a means of provoking the UAC prompt to run a command. It does not, and cannot, bypass the UAC prompt or Windows security controls.

**elevate** [**-n**] [**-q**] [**-w** _style_] [**-W** _dir_] **--** _command_ [_params_ [...]]

Parameter      | Long Form                 | Description
---------      | ---------                 | -----------
**-n**         | **--nowait**              | Don't wait for program to end
**-q**         | **--quiet**               | Run quietly (no dialog boxes)
**-w** _style_ | **--windowstyle**=_style_ | Specifies window style
**-W** _dir_   | **--workingdir**=_dir_    | Specifies working directory

_style_ is one of: **Normal** **NormalNotActive** **Minimized** **MinimizedNotActive** **Maximized** **Hidden**

Place all parameters at the start of the command line, in any order, followed by two dashes (**--**). The **--** indicates that what follows it is a command line. If you don't need any of the above parameters, it is still a good idea to use **--** before the command line to prevent command line parsing errors.

Everything after **--** is a command line you want to request to run elevated. If the current process is not elevated, you will receive a User Account Control (UAC) prompt to run the command.

Notes regading the **-W** (**--workingdir**) option:

* If the program you're requsting to elevate lives in the operating system's installation directory (or any subdirectory therein), and the current process is not already elevated, the **-W** (**--workingdir**) option is ignored, and the working directory for the program will be the operating system's `System32` directory.

* If the directory name contains spaces, enclose it in double quotes (`"`).

Without **-n** (**--nowait**), the exit code will be the exit code of the program. If the user cancels the elevation prompt, the exit code will be 1223.

---

### Usage 2

Usage 2 allows you to detect if the current process is running elevated (running as administrator). This can be useful from a script (e.g., you could tell the user that elevation is required and terminate the script).

**elevate** [**-q**] **-t**

Parameter | Long Form   | Description
--------- | ---------   | ------------
**-q**    | **--quiet** | Run quietly (no dialog boxes)
**-t**    | **--test**  | Test if current process is elevated

With **-t** (**--test**), the program's exit code will be 0 if the current process is not elevated, or 1 if the current process is elevated.
