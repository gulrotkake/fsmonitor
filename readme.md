!! This project has been superseded by the far more developed and maintained [fswatch](https://github.com/emcrisostomo/fswatch.git).

FSMonitor
-------

FSMonitor is an application to monitor changes in a directory structure
and execute actions depending on the events captured. It's built upon
the Mac OS X FSEvents API.

Usage:

    fsmonitor [dir1] [dir2] [...] --add --modify --exec /myscript

Global options:

    --recursive, -r : Scan directories recursively
    --verbose, -v   : Be verbose about program state


Per execution options:

    --add, -a    : When a file or directory is added
    --modify, -m : When a file or directory is modified
    --delete, -d : When a file or directory is deleted

When parsing the command line a watch flag is built using the above
actions until an `--exec` is encountered, which will then bind that
`--exec` to those actions and will reset the flag. This allows you to
bind multiple or different actions to different scripts. For example:

    fsmonitor . -a -m --exec ~/tests.sh -a -d --exec ~/updatedocs.sh


