climgur.sh
====

This script is used for adding and removing images to imgur from the command 
line.<br>
More features being added.

Keys can be grabbed : https://api.imgur.com/oauth2/addclient

Usage
----

<pre><code>

                          ___,A.A_  __
                          \   ,   7"_/
                           ~"T(  r r)
                             | \    Y
                             |  ~\ .|
                             |   |`-'
                             |   |
                             |   |
                             |   |
                             |   |
                             j   l
                            /     \
                           Y       Y
                           l   \ : |
                           /\   )( (
                          /  \  I| |\
                         Y    I l| | Y
                         j    ( )( ) l
                        / .    \ ` | |\
                       Y   \    i  | ! Y
                       l   .\_  I  |/  |
                        \ /   [\[][]/] j
                     ~~~~~~~~~~~~~~~~~~~~~~~
               _ _                                  _
           ___| (_)_ __ ___   __ _ _   _ _ __   ___| |__
          / __| | | '_ ` _ \ / _` | | | | '__| / __| '_ \
         | (__| | | | | | | | (_| | |_| | | _  \__ \ | | |
          \___|_|_|_| |_| |_|\__, |\__,_|_|(_) |___/_| |_|
                             |___/

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
                info
                    This option will show the details for the image
                screenshot
                    This option takes a screenshot and uploads it
                upload [path to file|path to folder]
                    This option allows for file uploads

    -l [options]
            This handles showing what is in the log folder
            Options include :
                clean
                    This option will remove the deleted files logs
                list
                    This option lists and shows log files

    -o      This opens image in either browser or feh

    -s      This bypasses using "-i screenshot" for quick screenshots

    -v      Show version

    This all reads the .climgur.rc file which should be located in
    $HOME/.climgur
    A sample rc file is in the github repo which shows what should be in there.

</code></pre>

Requirements
----

- Bash (https://www.gnu.org/software/bash/)
- Scrot (https://en.wikipedia.org/wiki/Scrot)
- cURL (http://curl.haxx.se/)
- feh (http://feh.finalrewind.org/)
- python (https://www.python.org/)
- xdg-utils (https://www.freedesktop.org/wiki/Software/xdg-utils/)

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
