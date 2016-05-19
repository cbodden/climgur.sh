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
            TMP_ALB=$(mktemp --tmpdir img_album_$$-XXXX.tmp)
            TMP_IMG=$(mktemp --tmpdir img_$$-XXXX.png)
            TMP_LOG=$(mktemp --tmpdir img_$$-XXXX.log)
        ;;
        'Darwin')
            TMP_ALB=$(mktemp --tmpdir img_album_$$-XXXX.tmp)
            TMP_IMG=$(mktemp img_$$-XXXX.png)
            TMP_LOG=$(mktemp img_$$-XXXX.log)
        ;;
        *)
            usage
            exit 1
        ;;
    esac
    trap 'rm -rf ${TMP_ALB} ${TMP_IMG} ${TMP_LOG} ; exit 1' 0 1 2 3 9 15

    # check if these deps exist else exit 1
    local DEPS="curl python scrot wget xdg-open"
    for _DEPS in ${DEPS}; do
        if [ -z "$(which ${_DEPS} 2>/dev/null)" ]; then
            printf "%s\n" "${_DEPS} not found"
            exit 1
        fi
    done

    # check if climgur log and rc path exists else create
    if [ ! -d "${CLIMGUR_PATH}" ]; then
        mkdir -p ${CLIMGUR_PATH} ${CLIMGUR_PATH}/.logs
    fi
    if [ ! -d "${CLIMGUR_PATH}/.logs" ]; then
        mkdir ${CLIMGUR_PATH}/.logs
    fi

    readonly LOG_PATH="${CLIMGUR_PATH}/.logs"

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
    local _ACCOUNT_TYPE_IN=${1}
    case "${ACCOUNT-$_ACCOUNT_TYPE_IN}" in
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

function album()
{
    if [ -e ${CLIMGUR_PATH}/.climgur_oauth2 ]; then
        source ${CLIMGUR_PATH}/.climgur_oauth2
    fi

    if [ -z ${ACCESS_TOKEN} ]; then
        local _AUTH="Client-ID ${CLIENT_ID}"
    else
        local _AUTH="Bearer ${ACCESS_TOKEN}"
    fi

    case "${ALBUM}" in
        'c'|'create')
            printf "\n\nAbout to create a new album for ${USER_NAME}.\n"
            printf "\nAlbum Name: "
            read _ALBUM_NAME
            printf "\nAlbum Title: "
            read _ALBUM_TITLE
            printf "\nAlbum Description: "
            read _ALBUM_DESC

            curl -X POST \
                -H "Authorization: ${_AUTH}" \
                -F "album=${_ALBUM_NAME}" \
                -F "title=${_ALBUM_TITLE}" \
                -F "description=${_ALBUM_DESC}" \
                "https://api.imgur.com/3/album" \
                | python -m json.tool \
                | sed -e 's/^ *//g' -e '/{/d' -e '/}/d' \
                | tee ${TMP_LOG}
            log album_create
        ;;
        'e'|'delete'|'erase')
            list_FOLDERS
            printf "\n\nEnter number and press [ENTER] or [x] to exit: "
            read ALBUM_IN
            if [ "${ALBUM_IN}" = "x" ]; then
                exit
            fi

            _AF=$(echo ${_A_LIST[$((ALBUM_IN-1))]} \
                | tr '%' ' ' \
                | awk '{print $2}')

            printf "\nYou selected: "
            printf "\n-- \"${_AF}\"\n"
            printf "\nPress [x] to exit or [ENTER] to continue: "
            read ALBUM_IN_CONFIRM

            if [ "${ALBUM_IN_CONFIRM}" = "x" ]; then
                exit
            fi

            printf "\nAbout to delete:"
            printf "\n${CLIMGUR_PATH}/${_AF}/\n"
            pause "Press [enter] to continue. "

            rm -rf "${CLIMGUR_PATH}/${_AF}/"
            printf "\n${CLIMGUR_PATH}/${_AF}/ deleted\n"
            exit
        ;;
        'd'|'download')
            printf "\n\nEnter album id and press [ENTER] or [x] to exit: "
            read ALBUM_IN

            curl -sH \
                "Authorization:Client-ID ${CLIENT_ID}" \
                https://api.imgur.com/3/album/${ALBUM_IN}/ \
                | python -m json.tool \
                | sed -e 's/^ *//g' -e '/{/d' -e '/}/d' \
                >> ${TMP_ALB}

            local ALBUM_ERROR=$(\
                grep -Po '"error":.*?[^\\]",' ${TMP_ALB} \
                | awk -F'"' '{print $4}')

            if [ -n "${ALBUM_ERROR}" ]; then
                printf "\n${ALBUM_ERROR}\n\n"
                exit 1
            fi

            local ALBUM_TITLE=$(\
                grep -Po '"title":.*?[^\\]",' ${TMP_ALB} \
                | tail -n 1 \
                | awk -F'"' '{print $4}' \
                | sed -e 's/[^A-Za-z0-9._-]/_/g' \
                | tr ' ' '_' )

            if [ -z "${ALBUM_TITLE}" ]; then
                ALBUM_TITLE="${ALBUM_IN}"
            fi

            declare -a _A_LINK=($(\
                grep -Po '"link":.*?[^\\]",' ${TMP_ALB} \
                | awk -F'"' '{print $4}' \
                | grep -v ${ALBUM_IN} ))

            declare -a _A_GIFV=($(\
                grep -Po '"gifv":.*?[^\\]",' ${TMP_ALB} \
                | awk -F'"' '{print $4}' ))

            declare -a _A_MP4=($(\
                grep -Po '"mp4":.*?[^\\]",' ${TMP_ALB} \
                | awk -F'"' '{print $4}' ))

            declare -a _A_WEBM=($(\
                grep -Po '"webm":.*?[^\\]",' ${TMP_ALB} \
                | awk -F'"' '{print $4}' ))

            printf "\nIs this the album you are looking for ?:"
            printf "\n-- \"${ALBUM_TITLE}\" with ${#_A_LINK[@]} images"
            printf "\n\nPress [x] to exit or [ENTER] to continue: "
            read ALBUM_IN_CONFIRM

            if [ "${ALBUM_IN_CONFIRM}" = "x" ]; then
                exit
            fi

            printf "\nAbout to download this gallery to:"
            printf "\n${CLIMGUR_PATH}/${ALBUM_TITLE/ /_}_${ALBUM_IN}\n\n"
            pause "Press [ENTER] to continue. "
            local _ALBUM_PATH="${CLIMGUR_PATH}/${ALBUM_TITLE/ /_}_${ALBUM_IN}"

            if [ ! -d "${_ALBUM_PATH}" ]; then
                mkdir -p ${_ALBUM_PATH}

            fi

            for ((CNT = 0; CNT < ${#_A_LINK[@]}; CNT++))
            do
                wget ${_A_LINK[$CNT]} --directory-prefix=${_ALBUM_PATH} -nv
            done
            printf "\n\nImages downloaded to ${_ALBUM_PATH}\n\n"

            if [ "${#_A_LINK[@]}" -eq "${#_A_GIFV[@]}" ]; then
                for ((CNT = 0; CNT < ${#_A_LINK[@]}; CNT++))
                do
                    wget ${_A_GIFV[$CNT]} --directory-prefix=${_ALBUM_PATH} -nv
                done
                printf "\n\nGifv files downloaded to ${_ALBUM_PATH}\n\n"

                for ((CNT = 0; CNT < ${#_A_LINK[@]}; CNT++))
                do
                    wget ${_A_MP4[$CNT]} --directory-prefix=${_ALBUM_PATH} -nv
                done
                printf "\n\nMp4 files downloaded to ${_ALBUM_PATH}\n\n"

                for ((CNT = 0; CNT < ${#_A_LINK[@]}; CNT++))
                do
                    wget ${_A_WEBM[$CNT]} --directory-prefix=${_ALBUM_PATH} -nv
                done
                printf "\n\nWebm files downloaded to ${_ALBUM_PATH}\n\n"
            fi
        ;;
        'l'|'list')
            list_FOLDERS
            printf "\n"
        ;;
    esac
}

function authentication()
{
    local OAUTH2="${CLIMGUR_PATH}/.climgur_oauth2"

    if [ ! -e "${OAUTH2}" ]; then
        touch ${OAUTH2}
    fi

    source ${OAUTH2}
    printf "\nWe need to get a pin number for authentication.\n"
    printf "\nCheck your browser and copy paste the pin below.\n"

    local AUTH="client_id=${CLIENT_ID}&response_type=pin&state=testing"

    xdg-open "https://api.imgur.com/oauth2/authorize?${AUTH}"

    printf "\nNow paste the pin here: "
    read OATH2_PIN

    if [ -z "${OATH2_PIN}" ]; then
        printf "\nNo pin number pasted"
        exit
    fi

    curl -s -X POST \
        -F "client_id=${CLIENT_ID}" \
        -F "client_secret=${CLIENT_SECRET}" \
        -F "grant_type=pin" \
        -F "pin=${OATH2_PIN}" \
        https://api.imgur.com/oauth2/token \
        | python -mjson.tool \
        | sed -e 's/^ *//g' -e '/{/d' -e '/}/d' -e 's/"//g' -e 's/,//g' \
        -e 's/: /="/g' -e 's/$/"/g' -e 's/[^ ]*=/\U\0/g' \
        > ${OAUTH2}

        printf "\nAuth info stored to ${OAUTH2}\n"
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
    if [ -e ${CLIMGUR_PATH}/.climgur_oauth2 ]; then
        source ${CLIMGUR_PATH}/.climgur_oauth2
    fi

    if [ -z ${ACCESS_TOKEN} ]; then
        local _AUTH="Client-ID ${CLIENT_ID}"
    else
        local _AUTH="Bearer ${ACCESS_TOKEN}"
    fi

    case "${IMAGE}" in
        'i'|'info')
            log list
        ;;
        'd'|'del'|'delete')
            list_IMAGES
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
            curl -X POST \
                -H "Authorization: ${_AUTH}" \
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
                curl -X POST \
                    -H 'Authorization:'" ${_AUTH}" \
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

function list_FOLDERS()
{
    local CNT=1

    declare -g _A_LIST=($(\
        for _A_LS in $(ls -v ${CLIMGUR_PATH})
        do
            printf "%s\n" "[${CNT}]%${_A_LS}"
            CNT=$((CNT+1))
        done))

    if [ $(echo ${#_A_LIST[@]}) -ge 1 ]; then
        for ((CNT_AL =0; CNT_AL < ${#_A_LIST[@]}; CNT_AL++))
        do
            echo "${_A_LIST[$CNT_AL]}" | tr '%' ' '
        done
    else
        printf "\nThere are no stored albums.\n\n"
        exit 1
    fi
}

function list_IMAGES()
{
    local CNT=1

    local _LIST=($(\
        for _LN in $(ls -v ${LOG_PATH} | grep -v "ALBUM")
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
    local _LOG_TYPE_IN=${1}
    case "${LOG_TYPE-$_LOG_TYPE_IN}" in
        'account_info') ;;
        'c'|'clean')
            rm -f ${LOG_PATH}/DELETED*
        ;;
        'album_create')
            local _ID=$(grep "\"id\"" ${TMP_LOG} | cut -d\" -f4)
            local _DH=$(grep "\"deletehash\"" ${TMP_LOG} | cut -d\" -f4)
            cp ${TMP_LOG} ${LOG_PATH}/ALBUM_${_ID}_${_DH}.log
        ;;
        'image_delete')
            LOG_NAME=${2}
            cat ${TMP_LOG} > ${LOG_PATH}/DELETED_${LOG_NAME}
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
            list_IMAGES
            local LIST_SHOW=${_LF}
            cat ${LOG_PATH}/${LIST_SHOW}
        ;;
    esac
}

function open()
{
    list_IMAGES
    local OPEN_SHOW="${_LF}"
    printf "\nOpen in browser or feh [(b)rowser or (f)eh]: "
    read OPEN_TYPE
    case "${OPEN_TYPE}" in
        'b'|'browser')
            xdg-open ${IMG_PATH}${OPEN_SHOW%%_*}.png
        ;;
        'f'|'feh')
            if [ -z "$(which feh 2>/dev/null)" ]; then
                printf "\nfeh not found\n"
                usage
                exit 1
            else
                feh --scale-down ${IMG_PATH}${OPEN_SHOW%%_*}.png
            fi
        ;;
    esac
}

function pause()
{
    read -p "$*"
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

    -d [options]
            This is to download an entire album
            Options include:
                delete
                    This option will delete the selected album locally
                download
                    This option will ask for an album id and download the
                    entire album to ${CLIMGUR_PATH}/(ALBUM ID)
                list
                    This option lists all the downloaded albums

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
                    This option lists and shows log files located at:
                    ${LOG_PATH}

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
while getopts "acd:hi:l:osv" OPT; do
    case "${OPT}" in
        'a') account info ;;
        'c') authentication ;;
        'd') ALBUM=${OPTARG}
            album ;;
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
