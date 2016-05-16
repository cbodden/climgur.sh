#!/usr/bin/env bash

set -e
set -o pipefail
readonly NAME=$(basename $0)
readonly VER="0.35"
readonly CLIMGUR_PATH="${HOME}/.climgur"
readonly IMG_PATH="http://i.imgur.com/"

function main()
{
    # temp file, trap statement, and OS check. exit on !{Linux,Darwin}
    case "$(uname 2>/dev/null)" in
        'Linux')
            TMP_IMG=$(mktemp --tmpdir img_$$-XXXX.png)
            TMP_LOG=$(mktemp --tmpdir img_$$-XXXX.log)
        ;;
        'Darwin')
            TMP_IMG=$(mktemp img_$$-XXXX.png)
            TMP_LOG=$(mktemp img_$$-XXXX.log)
        ;;
        *)
            usage
            exit 1
        ;;
    esac
    trap 'rm -rf ${TMP_IMG} ${TMP_LOG} ; exit 1' 0 1 2 3 9 15

    # check if these deps exist else exit 1
    local DEPS="curl feh python scrot xdg-open"
    for _DEPS in ${DEPS}; do
        if [ -z "$(which ${_DEPS} 2>>/dev/null)" ]; then
            printf "%s\n" "${_DEPS} not found"
            exit 1
        fi
    done

    # check if climgur log and rc path exists else create
    if [ ! -d "${CLIMGUR_PATH}" ]; then
        mkdir -p ${CLIMGUR_PATH} ${CLIMGUR_PATH}/logs
    fi
    if [ ! -d "${CLIMGUR_PATH}/logs" ]; then
        mkdir ${CLIMGUR_PATH}/logs
    fi

    readonly LOG_PATH="${CLIMGUR_PATH}/logs"

    # check for .climgur.rc exists
    if [ ! -e "${CLIMGUR_PATH}/.climgur.rc" ]; then
        printf "%s\n" ".climgur.rc does not exist. Check the usage section."
        exit 1
    else
        source ${CLIMGUR_PATH}/.climgur.rc
        local RC_LIST="CLIENT_ID CLIENT_SECRET USER_NAME"
        for _RC_LIST in ${RC_LIST}; do
            if [ -z "${_RC_LIST}" ]; then
                printf "%s\n" "${_RC_LIST} is not set"
            fi
        done
    fi

    clear
}

function account()
{
    case "${ACCOUNT}" in
        'i'|'info')
            curl -sH \
                "Authorization:Client-ID ${CLIENT_ID}" \
                https://api.imgur.com/3/account/${USER_NAME} \
                | python -m json.tool \
                | sed -e 's/^ *//g' -e '/{/d' -e '/}/d' \
                | tee ${TMP_LOG}
            log account_info
        ;;
        *) printf "\nAccount function\n\n" ;;
    esac
}

function giraffe()
{
# created with cat file | gzip | base64
# image from http://chris.com/ascii/index.php?art=animals/other (land)
GIRAFFE="
H4sIAJ5EOVcAA82TsY6DMAyGd57ivy4NEsVjpW4du9+CCHLXVkydLZ79bIdK5VRMx8Y4Aecjdpy4
wmpj5ubcntneqnUsqzaqxx1TgGHa/SbggUcdUYD4iui2KEwZrWxSkOth/wH1JchddQwR8j5HTPcc
I2i0VXCKAyI7izohBRD5HbgIJAjKQ7pgVCoKy7aPZB7rIA2EFh79FZHXDuV24map/1n3a6loM1uA
EIrOKHv6+9wP/UAD7u/B6X37D7PKZluUnpakIHGtf9rDbprX8ZGfkCxqluA2lT1r0tj3wZ692arT
BVLgJaHmjQVLScUy29VlZlvRP1+cZgukCGZVUwPvzaobsTiZyuRG7RhY/QH3bBhfrwQAAA=="
echo "${GIRAFFE}" | base64 -d | gunzip
}

function image()
{
    case "${IMAGE}" in
        'i'|'info')
            log list
        ;;
        'd'|'del'|'delete')
            list
            local DEL_LIST_SHOW="${_LF}"
            local HASH="$(echo ${DEL_LIST_SHOW##*_} | cut -d. -f1)"
            curl -sH "Authorization: Client-ID ${CLIENT_ID}" \
                -X DELETE \
                "https://api.imgur.com/3/image/${HASH}" \
                | python -m json.tool \
                | sed -e 's/^ *//g' -e '/{/d' -e '/}/d' \
                | tee ${TMP_LOG}
            printf "\n${IMG_PATH}${DEL_LIST_SHOW%%_*}.png deleted\n"
            log image_delete ${DEL_LIST_SHOW}
        ;;
        's'|'ss'|'screenshot')
            $(which scrot) -z ${TMP_IMG} >/dev/null 2>&1
            curl -sH "Authorization: Client-ID ${CLIENT_ID}" \
                -F "image=@${TMP_IMG}" \
                "https://api.imgur.com/3/upload" \
                | python -m json.tool \
                | sed -e 's/^ *//g' -e '/{/d' -e '/}/d' \
                | tee ${TMP_LOG}
            log image_screenshot
        ;;
        'u'|'upload')
            printf "Path to file ? (tab complete full path) : "
            read -e _FILE_PATH
            eval _FILE_PATH=${_FILE_PATH}
            if grep -q "image data" <(file "${_FILE_PATH}"); then
                curl -sH "Authorization: Client-ID ${CLIENT_ID}" \
                    -F "image=@${_FILE_PATH}" \
                    "https://api.imgur.com/3/upload" \
                    | python -m json.tool \
                    | sed -e 's/^ *//g' -e '/{/d' -e '/}/d' \
                    | tee ${TMP_LOG}
                log image_upload
            else
                usage;
            fi
        ;;
        *) usage ;;
    esac
}

function list()
{
    local CNT=1
    local _LIST=($(\
        for _LN in $(ls -v ${LOG_PATH})
        do
            printf "%s\n" "[${CNT}]%${_LN}%--%${IMG_PATH}${_LN%%_*}.png"
            CNT=$((CNT+1))
        done))

    if [ $(echo ${#_LIST[@]}) -ge 1 ]; then
        for ((CNT_L = 0; CNT_L < ${#_LIST[@]}; CNT_L++))
        do
            echo "${_LIST[$CNT_L]}" | tr '%' ' '
        done
    else
        printf "\nLog directory is empty.\n\n"
        exit 1
    fi

    printf "\n\nEnter log / image number and press [ENTER] or [x] to exit: "
    read LIST_IN
    if [ ${LIST_IN} = "x" ]; then
        exit
    fi
    _LF=$(echo ${_LIST[$((LIST_IN-1))]} \
        | tr '%' ' ' \
        | awk '{print $2}')
}

function log()
{
    local _LTYPE=${1}
    case "${LOG_TYPE-$_LTYPE}" in
        'account_info') ;;
        'c'|'clean')
            rm -f ${LOG_PATH}/deleted*
        ;;
        'image_delete')
            LOG_NAME=${2}
            cat ${TMP_LOG} > ${LOG_PATH}/deleted_${LOG_NAME}
            rm ${LOG_PATH}/${LOG_NAME}
        ;;
        'image_screenshot')
            local _ID=$(grep "\"id\"" ${TMP_LOG} | cut -d\" -f4)
            local _DH=$(grep "\"deletehash\"" ${TMP_LOG} | cut -d\" -f4)
            cp ${TMP_LOG} ${LOG_PATH}/${_ID}_${_DH}.log
        ;;
        'image_upload')
            local _ID=$(grep "\"id\"" ${TMP_LOG} | cut -d\" -f4)
            local _DH=$(grep "\"deletehash\"" ${TMP_LOG} | cut -d\" -f4)
            cp ${TMP_LOG} ${LOG_PATH}/${_ID}_${_DH}.log
        ;;
        'list')
            list
            local LIST_SHOW=${_LF}
            cat ${LOG_PATH}/${LIST_SHOW}
        ;;
    esac
}

function open()
{
    list
    local OPEN_SHOW="${_LF}"
    printf "\nOpen in browser or feh [(b)rowser or (f)eh]: "
    read OPEN_TYPE
    case "${OPEN_TYPE}" in
        'b'|'browser')
            xdg-open ${IMG_PATH}${OPEN_SHOW%%_*}.png
        ;;
        'f'|'feh')
            feh --scale-down ${IMG_PATH}${OPEN_SHOW%%_*}.png
        ;;
    esac
}

function usage()
{
cat <<EOL

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

EOL
}

function version()
{
    cat <<EOL

                             ${NAME} version ${VER}
                  Copyright (C) 2016 cesar@pissedoffadmins.com
                This program comes with ABSOLUTELY NO WARRANTY.
         This is free software, and you are welcome to redistribute it.

EOL
}

# call function main
main
giraffe
# the actual selector of the script
while getopts "ahi:l:osv" OPT; do
    case "${OPT}" in
        'a') account_info ;;
        'h') usage ;;
        'i') IMAGE=${OPTARG}
            image ;;
        'l') LOG_TYPE=${OPTARG}
            log ;;
        'o') open ;;
        's') IMAGE="screenshot"
            image ;;
        'v') version ;;
    esac
done
[ ${OPTIND} -eq 1 ] && { usage ; }
shift $((OPTIND-1))
