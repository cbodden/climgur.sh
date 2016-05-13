#!/usr/bin/env bash

set -e
set -o pipefail
readonly NAME=$(basename $0)
readonly VER="0.01"
source .climgur.rc

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
    *) version; description; usage; exit 1 ;;
esac
trap 'rm -rf ${TMP_IMG} ${TMP_LOG} ; exit 1' 0 1 2 3 9 15

# check if curl exists
[ -z $(which curl 2>/dev/null) ] \
    && { printf "%s\n" "curl not found"; exit 1; }

#check if python exists for json.tool
[ -z $(which python 2>/dev/null) ] \
    && { printf "%s\n" "python not found"; exit 1; }

# check if scrot exists
[ -z $(which scrot 2>/dev/null) ] \
    && { printf "%s\n" "scrot not found"; exit 1; }

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
    local LOG_TYPE=$1
    local LOG_PATH="${HOME}/.climgur_logs"
    [ ! -d "${LOG_PATH}" ] \
        && { mkdir ${LOG_PATH} ; }

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
                    echo [${CNT}] ${_listL}
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

            echo ${LIST_SHOW}
            cat ${LOG_PATH}${LIST_SHOW}
        ;;
    esac
}

function usage()
{
    printf "\ntesting\n\n"
}

while getopts "ahi:s" OPT; do
    case "${OPT}" in
        a) account_info ;;
        h) usage ;;
        i) IMAGE=$OPTARG
            image ;;
        s) IMAGE="screenshot"
            image ;;
    esac
done
[ ${OPTIND} -eq 1 ] && { usage ; }
shift $((OPTIND-1))
