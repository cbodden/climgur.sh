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
            description
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

    readonly LOG_PATH="${CLIMGUR_PATH}/logs"

    # check for .climgur.rc exists
    if [ ! -e "${CLIMGUR_PATH}/.climgur.rc" ]; then
        printf "%s\n" ".climgur.rc does not exist."
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
            printf "deletehash of image to be deleted ? : " ; read _FILE_DEL
            curl -sH "Authorization: Client-ID ${CLIENT_ID}" \
                -X DELETE \
                "https://api.imgur.com/3/image/${_FILE_DEL}" \
                | python -m json.tool \
                | sed -e 's/^ *//g' -e '/{/d' -e '/}/d' \
                | tee ${TMP_LOG}
            log image_delete
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
    case "${LOG_TYPE}" in
        account_info) ;;
        image_delete) ;;
        image_screenshot)
            _ID=$(grep "\"id\"" ${TMP_LOG} | cut -d\" -f4)
            _DH=$(grep "\"deletehash\"" ${TMP_LOG} | cut -d\" -f4)
            cp ${TMP_LOG} ${LOG_PATH}/${_ID}_${_DH}.log
        ;;
        image_upload)
            _ID=$(grep "\"id\"" ${TMP_LOG} | cut -d\" -f4)
            _DH=$(grep "\"deletehash\"" ${TMP_LOG} | cut -d\" -f4)
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
            elif [ $(echo ${#_LIST[@]}) -eq 1 ]; then
                local LIST_SHOW="$(echo ${_LIST[1]})"
            else
                printf -- "File not found \n\n" exit 1
            fi

            cat ${LOG_PATH}/${LIST_SHOW}
        ;;
    esac
}

function usage()
{
    printf "\ntesting\n\n"
}

# call function main
main

# the actual selector of the script
while getopts "ahi:l:s" OPT; do
    case "${OPT}" in
        a) account_info ;;
        h) usage ;;
        i) IMAGE=$OPTARG
            image ;;
        l) LOG_TYPE=$OPTARG
            log ;;
        s) IMAGE="screenshot"
            image ;;
    esac
done
[ ${OPTIND} -eq 1 ] && { usage ; }
shift $((OPTIND-1))
