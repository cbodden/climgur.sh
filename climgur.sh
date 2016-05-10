#!/usr/bin/env bash

# vim:set ts=2 sw=4 noexpandtab:
# <cesar@pissedoffadmins.com> 2013

set -e
set -o pipefail
clear
local NAME=$(basename $0)
local APIKEY=""

version()
{
  local VER="0.01"
cat <<EOL
${NAME} version ${VER}
Copyright (C) 2016 cesar@pissedoffadmins.com
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it.

EOL
}

descrip()
{
  cat <<EOL

EOL
}

usage()
{
  cat <<EOL

EOL
}

# temp file and trap statement - trap for clean end
case "$(uname 2>/dev/null)" in
  'Linux') TMP_FILE=$(mktemp --tmpdir img_$$-XXXXXX.png) ;;
  'Darwin') TMP_FILE=$(mktemp img_$$-XXXXXX.png) ;;
esac
trap 'printf "${NAME}: Quitting.\n\n" 1>&2 ; \
   rm -rf ${TMP_FILE} ; exit 1' 0 1 2 3 9 15

# check if scrot exists
[ -z $(which scrot 2>/dev/null) ] &&\
    { printf "%s\n" "scrot not found"; exit 1; }

# check if curl exists
[ -z $(which curl 2>/dev/null) ] &&\
    { printf "%s\n" "curl not found"; exit 1; }
