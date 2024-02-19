#!/bin/bash

# GFWLIST_REMOTE=https://gitlab.com/gfwlist/gfwlist/raw/master/gfwlist.txt
GFWLIST_REMOTE=https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt

GFWLIST=${GFWLIST_REMOTE##*/}
GFWLIST_DEC=gfwlist_dec.txt

update_gfwlist() {
    rm $GFWLIST

    wget $GFWLIST_REMOTE
    if test $?; then
        echo "Got gfwlist from remote: $GFWLIST_REMOTE"
    else
        echo "failed to get gfwlist from remote: $GFWLIST_REMOTE"
        return 1
    fi

    cat ${GFWLIST} | base64 -d >$GFWLIST_DEC
    if test $?; then
        echo "gfwlist updated!"
    else
        echo "failed to update gfwlist!"
        return 1
    fi

    # https://github.com/gfwlist/gfwlist/wiki/Syntax
}

gen_test() {
    local TYPE="$1"
    local DATA="$2"
    echo $TYPE $DATA
}

gen_kitsunebi_rule() {
    local TYPE="$1"
    local DATA="$2"

    if test "$TYPE" = "match-domain"; then
        echo "DOMAIN,${DATA%%/*},PROXY,force-remote-dns"
    elif test "$TYPE" = "match-domain-surfix"; then
        echo "DOMAIN-SUFFIX,${DATA%%/*},PROXY,force-remote-dns"
    else
        echo "" >/dev/null
    fi
}

do_work() {
    local CMD="$*"
    local TYPE=""
    local DATA=""
    while read LINE; do
        if test -z "$LINE"; then
            continue
        fi
        if test "${LINE:0:1}" = "!"; then
            TYPE="comment"
            DATA="${LINE:1}"
        elif test "${LINE:0:1}" = "["; then
            TYPE="section"
            DATA="${LINE:1:-1}"
        elif test "${LINE:0:2}" = "||"; then
            TYPE="match-domain-surfix"
            DATA="${LINE:2}"
        elif test "${LINE:0:1}" = "."; then
            TYPE="match-domain-surfix"
            DATA="${LINE:1}"
        elif test "${LINE:0:1}" = "|"; then
            TYPE="match-domain-name"
            DATA="${LINE:1}"
        elif test "${LINE:0:4}" = "@@||"; then
            TYPE="unmatch-domain-surfix"
            DATA="${LINE:4}"
        elif test "${LINE:0:3}" = "@@|"; then
            TYPE="unmatch-domain-name"
            DATA="${LINE:3}"
        elif test "${LINE:0:1}" = "/"; then
            TYPE="match-domain-regex"
            DATA="${LINE:1:-1}"
        else
            IP=$(echo $LINE | grep -P '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
            if test -z "$IP"; then
                TYPE="match-domain"
                DATA="${LINE}"
            else
                TYPE="match-ip"
                DATA="${IP}"
            fi
        fi

        eval $CMD '"${TYPE}" "${DATA}"'
    done <${GFWLIST_DEC}
}

do_work_test() {
    do_work gen_test
}

do_work_kitsunebi() {
    local FN="$1"
    echo "[Rule]" >$FN
    local tmpfile=$(mktemp)
    do_work gen_kitsunebi_rule >>${tmpfile}
    cat $tmpfile | grep -v '[=%]' | awk '!(NF && seen[$0]++)' >>$FN
    rm $tmpfile
    echo "" >>$FN
    echo "FINAL,DIRECT" >>$FN

    cat >>$FN <<EOF

[DnsServer]
223.5.5.5
119.29.29.29
8.8.8.8,53,REMOTE
EOF

}

case $1 in
update)
    update_gfwlist
    ;;
kitsunebi)
    do_work_kitsunebi kitsunebi_blacklist.conf
    ;;
*)
    do_work_test
    ;;
esac
