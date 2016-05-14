#!/usr/bin/env bash

set -e
set -o pipefail
readonly NAME=$(basename $0)
readonly VER="0.20"
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
    local DEPS="curl python scrot"
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

function image()
{
    case "${IMAGE}" in
        'd'|'del'|'delete')
            local D_CNT=0
            declare -a _DEL_LIST=($(\
                for _LN in $(ls -v ${LOG_PATH})
                do
                    echo ${_LN}
                done))

            if [ $(echo ${#_DEL_LIST[@]}) -ge 1 ]; then
                printf -- "%s\n" "Here is the list of files:"
                for _listL in "${_DEL_LIST[@]}"
                do
                    printf "%s" \
                        "[${D_CNT}] ${_listL}  --  ${IMG_PATH}${_listL%%_*}.png"
                    local D_CNT=$((D_CNT+1))
                done
                printf "\n\nEnter log number to delete and press [ENTER]: "
                read DEL_LIST_IN
                local DEL_LIST_SHOW="${_DEL_LIST[${DEL_LIST_IN}]}"
            elif [ $(echo ${#_DEL_LIST[@]}) -eq 1 ]; then
                local DEL_LIST_SHOW="$(echo ${_DEL_LIST[1]})"
            else
                printf -- "File not found \n\n" exit 1
            fi

            local HASH="$(echo ${DEL_LIST_SHOW##*_} | cut -d. -f1)"

            curl -sH "Authorization: Client-ID ${CLIENT_ID}" \
                -X DELETE \
                "https://api.imgur.com/3/image/${HASH}" \
                | python -m json.tool \
                | sed -e 's/^ *//g' -e '/{/d' -e '/}/d' \
                | tee ${TMP_LOG}
            printf "\n${IMG_PATH}${_listL%%_*}.png deleted\n"
            log image_delete ${_listL}
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
            printf "Path to file ? (full path) : " ; read _FILE_PATH
            if grep -q "image data" <(file ${_FILE_PATH}); then
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
        *) printf "\nImage function\n\n" ;;
    esac
}

function log()
{
    local LOG_TYPE=${1}
    case "${LOG_TYPE}" in
        account_info) ;;
        image_delete)
            LOG_NAME=${2}
            cat ${TMP_LOG} > ${LOG_PATH}/deleted_${LOG_NAME}
            rm ${LOG_PATH}/${LOG_NAME}
        ;;
        image_screenshot)
            local _ID=$(grep "\"id\"" ${TMP_LOG} | cut -d\" -f4)
            local _DH=$(grep "\"deletehash\"" ${TMP_LOG} | cut -d\" -f4)
            cp ${TMP_LOG} ${LOG_PATH}/${_ID}_${_DH}.log
        ;;
        image_upload)
            local _ID=$(grep "\"id\"" ${TMP_LOG} | cut -d\" -f4)
            local _DH=$(grep "\"deletehash\"" ${TMP_LOG} | cut -d\" -f4)
            cp ${TMP_LOG} ${LOG_PATH}/${_ID}_${_DH}.log
        ;;
        list)
            local CNT=0
            declare -a _LIST=($(\
                for _LN in $(ls -v ${LOG_PATH})
                do
                    echo ${_LN}
                done))

            if [ $(echo ${#_LIST[@]}) -ge 1 ]; then
                printf -- "%s\n" "Here is the list of files:"
                for _listL in "${_LIST[@]}"
                do
                    echo "[${CNT}] ${_listL}  --  ${IMG_PATH}${_listL%%_*}.png"
                    local CNT=$((CNT+1))
                done
                printf "%s" "Enter log number and press [ENTER]: "
                read LIST_IN
                local LIST_SHOW="${_LIST[${LIST_IN}]}"
                cat ${LOG_PATH}/${LIST_SHOW}
            elif [ $(echo ${#_LIST[@]}) -eq 1 ]; then
                local LIST_SHOW="$(echo ${_LIST[1]})"
                cat ${LOG_PATH}/${LIST_SHOW}
            else
                printf "\nLog directory is empty.\n\n" exit 1
            fi
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

# the actual selector of the script
while getopts "ahi:l:sv" OPT; do
    case "${OPT}" in
        a) account_info ;;
        h) usage ;;
        i) IMAGE=$OPTARG
            image ;;
        l) log list ;;
        s) IMAGE="screenshot"
            image ;;
        v) version ;;
    esac
done
[ ${OPTIND} -eq 1 ] && { usage ; }
shift $((OPTIND-1))
