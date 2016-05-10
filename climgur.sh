#!/usr/bin/env bash

set -e
set -o pipefail
clear
readonly NAME=$(basename $0)
readonly APIKEY=""
readonly VER="0.01"

# temp file and trap statement - trap for clean end
case "$(uname 2>/dev/null)" in
    'Linux') local TMP_FILE=$(mktemp --tmpdir img_$$-XXXXXX.png) ;;
    'Darwin') local TMP_FILE=$(mktemp img_$$-XXXXXX.png) ;;
esac

trap 'printf "${NAME}: Quitting.\n\n" 1>&2 ; \
    rm -rf ${TMP_FILE} ; exit 1' 0 1 2 3 9 15

# check if scrot exists
[ -z $(which scrot 2>/dev/null) ] &&\
    { printf "%s\n" "scrot not found"; exit 1; }

# check if curl exists
[ -z $(which curl 2>/dev/null) ] &&\
    { printf "%s\n" "curl not found"; exit 1; }

function screenshot()
{

