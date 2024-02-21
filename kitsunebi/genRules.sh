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

    echo "# $(date)" >$FN

    cat >>$FN <<EOF
[Rule]
# LAN
GEOIP,private,DIRECT

# DNS
IP-CIDR,119.29.29.29/32,DIRECT
IP-CIDR,223.5.5.5/32,DIRECT
IP-CIDR,1.1.1.1/32,PROXY
IP-CIDR,1.0.0.1/32,PROXY
IP-CIDR,8.8.8.8/32,PROXY
IP-CIDR,8.8.4.4/32,PROXY
IP-CIDR,9.9.9.9/32,PROXY
IP-CIDR,149.112.112.112/32,PROXY
IP-CIDR,208.67.222.222/32,PROXY
IP-CIDR,208.67.220.220/32,PROXY

// LINE
IP-CIDR,125.209.222.0/22,Proxy,no-resolve
IP-CIDR,203.104.128.0/20,Proxy,no-resolve

// Telegram
IP-CIDR,149.154.167.0/22,Proxy,no-resolve
IP-CIDR,149.154.175.0/22,Proxy,no-resolve
IP-CIDR,91.108.56.0/22,Proxy,no-resolve

DOMAIN-KEYWORD,geosite:category-ads-all,DIRECT
USER-AGENT,wechat,DIRECT

USER-AGENT,twitter,PROXY,force-remote-dns
DOMAIN-KEYWORD,twitter,PROXY,force-remote-dns

USER-AGENT,gmail,PROXY,force-remote-dns
DOMAIN-KEYWORD,gmail,PROXY,force-remote-dns

USER-AGENT,telegram,PROXY,force-remote-dns
DOMAIN-KEYWORD,telegram,PROXY,force-remote-dns

USER-AGENT,tumblr,PROXY,force-remote-dns
DOMAIN-KEYWORD,tumblr,PROXY,force-remote-dns

USER-AGENT,facebook,PROXY,force-remote-dns
DOMAIN-KEYWORD,facebook,PROXY,force-remote-dns

USER-AGENT,pinterest,PROXY,force-remote-dns
DOMAIN-KEYWORD,pinterest,PROXY,force-remote-dns

USER-AGENT,instagram,PROXY,force-remote-dns
DOMAIN-KEYWORD,instagram,PROXY,force-remote-dns

# 
DOMAIN-KEYWORD,google,PROXY,force-remote-dns
DOMAIN-KEYWORD,youtube,PROXY,force-remote-dns
DOMAIN-KEYWORD,github,PROXY,force-remote-dns
DOMAIN-KEYWORD,gitlab,PROXY,force-remote-dns
DOMAIN-KEYWORD,yahoo,Proxy,force-remote-dns
DOMAIN-KEYWORD,wikipedia,Proxy,force-remote-dns
DOMAIN-KEYWORD,telegram,Proxy,force-remote-dns
DOMAIN-KEYWORD,whatsapp,Proxy,force-remote-dns
DOMAIN-KEYWORD,line,Proxy,force-remote-dns
DOMAIN-KEYWORD,blogspot,Proxy,force-remote-dns
DOMAIN-KEYWORD,shadowsocks,Proxy,force-remote-dns
DOMAIN-KEYWORD,skype,Proxy,force-remote-dns
DOMAIN-KEYWORD,bing,Proxy,force-remote-dns
DOMAIN-KEYWORD,netflix,Proxy,force-remote-dns
DOMAIN-KEYWORD,snapchat,Proxy,force-remote-dns
DOMAIN-KEYWORD,openai,Proxy,force-remote-dns
DOMAIN-SUFFIX,character.ai,Proxy,force-remote-dns
DOMAIN-SUFFIX,v2ex.com,Proxy,force-remote-dns
DOMAIN-KEYWORD,dropbox,Proxy,force-remote-dns
DOMAIN-KEYWORD,quora,Proxy,force-remote-dns
DOMAIN-KEYWORD,reddit,Proxy,force-remote-dns
DOMAIN-KEYWORD,wired,Proxy,force-remote-dns
DOMAIN-KEYWORD,bloomberg,Proxy,force-remote-dns
DOMAIN-KEYWORD,stackoverflow,Proxy,force-remote-dns
DOMAIN-KEYWORD,stackexchange,Proxy,force-remote-dns

DOMAIN-SUFFIX,appsto.re,Proxy
DOMAIN,s.mzstatic.com,Proxy
DOMAIN,gspe1-ssl.ls.apple.com,Proxy
DOMAIN,news-events.apple.com,Proxy
DOMAIN,news-client.apple.com,Proxy

DOMAIN-KEYWORD,geosite:gfw,Proxy,force-remote-dns


EOF

    local tmpfile=$(mktemp)
    do_work gen_kitsunebi_rule >>${tmpfile}
    cat $tmpfile | grep -v '[=%]' | awk '!(NF && seen[$0]++)' >>$FN
    rm $tmpfile

    cat >>$FN <<EOF

DOMAIN-KEYWORD,geosite:cn,DIRECT

FINAL,DIRECT

EOF

    cat >>$FN <<EOF

[DnsServer]
# first one has higher priority
1.1.1.1
8.8.8.8,53,force-remote-dns
223.5.5.5,53,force-domestic-dns

[DnsRule]
DOMAIN-KEYWORD,google,force-remote-dns
DOMAIN-KEYWORD,geosite:cn,force-domestic-dns
DOMAIN-KEYWORD,tencent,force-domestic-dns
DOMAIN-KEYWORD,huawei,force-domestic-dns
DOMAIN-KEYWORD,aliyun,force-domestic-dns
DOMAIN-KEYWORD,alibaba,force-domestic-dns
DOMAIN-KEYWORD,ugreen,force-domestic-dns
DOMAIN-KEYWORD,synology,force-domestic-dns
DOMAIN-SUFFIX,oray.com,force-domestic-dns
DOMAIN-KEYWORD,lenovo.com,force-domestic-dns


[DnsHost]
# Static DNS map that functions in the same way as /etc/hosts.
localhost=127.0.0.1
www.localnetwork.uop=127.0.0.1
abcd.com=1.2.3.4

[DnsClientIp]
# Client IP for EDNS Client Subnet extension, a single IP address.
115.239.211.92

[RoutingDomainStrategy]
# https://www.v2ray.com/chapter_02/03_routing.html
IPIfNonMatch

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
