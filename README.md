climgur.sh
====

This script is used for adding and removing images to imgur from the command 
line.<br>
More features being added.

Usage
----

<pre><code>
NAME
    climgur.sh - this is for adding and deleting images from imgur

SYNOPSIS
    climgur.sh [OPTION]... [FILE]...

DESCRIPTION
    Access your Imgur account from the command line.
    Options can only be used one at a time for now.


    -a      Access your account info.

    -h      Show this file (usage).

    -i [options]
            This is to handle images manipulations
            Options include :
                delete
                    This option shows a list of files with choice of delete
                screenshot
                    This option takes a screenshot and uploads it
                upload [path to file|path to folder]
                    This option allows for file uploads

    -l [options]
            This handles showing what is in the log folder
            Options include :
                list
                    This option lists and shows log files

    -s      This bypasses using "-i screenshot" for quick screenshots

    -v      Show version

    This all reads the .climgur.rc file which should be located in
    $HOME/.climgur
    A sample rc file is in the github repo which shows what should be in there.

</code></pre>

Requirements
----

- Bash (https://www.gnu.org/software/bash/)
- cURL (http://curl.haxx.se/)
- python (https://www.python.org/)
- Scrot (https://en.wikipedia.org/wiki/Scrot)

Todo / Add
----


License and Author
----

Author:: Cesar Bodden (cesar@pissedoffadmins.com)

Copyright:: 2016, Pissedoffadmins.com

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
