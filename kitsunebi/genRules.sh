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
IP-CIDR,223.6.6.6/32,DIRECT
IP-CIDR,114.114.114.114/32,DIRECT
IP-CIDR,1.1.1.1/32,PROXY
IP-CIDR,1.0.0.1/32,PROXY
IP-CIDR,8.8.8.8/32,PROXY
IP-CIDR,8.8.4.4/32,PROXY
IP-CIDR,9.9.9.9/32,PROXY
IP-CIDR,9.9.9.10/32,PROXY
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

USER-AGENT,wechat,DIRECT
# DOMAIN-KEYWORD,geosite:category-ads-all,REJECT

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

# DOMAIN-KEYWORD,geosite:gfw,Proxy,force-remote-dns


EOF

    local tmpfile=$(mktemp)
    do_work gen_kitsunebi_rule >>${tmpfile}
    cat $tmpfile | grep -v '[=%*]' | awk '!(NF && seen[$0]++)' >>$FN
    rm $tmpfile

    cat >>$FN <<EOF

# DOMAIN-KEYWORD,geosite:cn,DIRECT

FINAL,DIRECT

EOF

    cat >>$FN <<EOF

[DnsServer]
# first one has higher priority
223.6.6.6,53,alidns1

# 8.8.8.8,53,googledns0
8.8.4.4,53,googledns1

# 216.146.35.35,53,Dyn
# 95.85.95.85,53,gcore
# 149.112.112.112,53,quad9_2
# 9.9.9.9,53,quad9_0
# 9.9.9.10,53,quad9_1

# 103.247.36.36,53,dnsfilter0
# 103.247.37.37,53,dnsfilter1
# 208.67.222.222,53,cisco0
# 208.67.220.220,53,cisco1
# 208.67.222.220,53,cisco2
# 195.46.39.39,53,safedns
# 185.228.168.9,53,cleanbrowsing

# 94.140.15.15,53,adguard1
# 94.140.14.140,53,adguard2

# 1.1.1.1,53,cloudfare0
# 1.1.1.2,53,cloudfare1
# 1.0.0.1,53,cloudfare3
# 1.0.0.2,53,cloudfare4
# 1.0.0.3,53,cloudfare5

# 223.5.5.5,53,alidns0
# 223.6.6.6,53,alidns1

# 119.29.29.29,53,dnspod
# 114.114.114.114,53,114dns

[DnsRule]
# DOMAIN-KEYWORD,tencent,dnspod
# DOMAIN-KEYWORD,huawei,dnspod
# DOMAIN-KEYWORD,aliyun,alidns1
# DOMAIN-KEYWORD,alibaba,alidns1
# DOMAIN-KEYWORD,ugreen,dnspod
# DOMAIN-KEYWORD,ugnas,dnspod
# DOMAIN-KEYWORD,synology,googledns1
# DOMAIN-KEYWORD,meituan,114dns
# DOMAIN-KEYWORD,geosite:cn,alidns1

# DOMAIN-KEYWORD,cloudfare,cloudfare1
DOMAIN-KEYWORD,twitter,googledns1
DOMAIN-KEYWORD,google,googledns1
DOMAIN-KEYWORD,youtube,googledns1
DOMAIN-KEYWORD,gmail,googledns1
DOMAIN-KEYWORD,telegram,googledns1
DOMAIN-KEYWORD,tumblr,googledns1
DOMAIN-KEYWORD,facebook,googledns1
DOMAIN-KEYWORD,pinterest,googledns1
DOMAIN-KEYWORD,instagram,googledns1
DOMAIN-KEYWORD,github,googledns1
DOMAIN-KEYWORD,gitlab,googledns1
DOMAIN-KEYWORD,yahoo,googledns1
DOMAIN-KEYWORD,wikipedia,googledns1
DOMAIN-KEYWORD,telegram,googledns1
DOMAIN-KEYWORD,whatsapp,googledns1
DOMAIN-KEYWORD,line,googledns1
DOMAIN-KEYWORD,blogspot,googledns1
DOMAIN-KEYWORD,shadowsocks,googledns1
DOMAIN-KEYWORD,skype,googledns1
DOMAIN-KEYWORD,bing,googledns1
DOMAIN-KEYWORD,netflix,googledns1
DOMAIN-KEYWORD,snapchat,googledns1
DOMAIN-KEYWORD,openai,googledns1
DOMAIN-KEYWORD,v2ex,googledns1
DOMAIN-KEYWORD,dropbox,googledns1
DOMAIN-KEYWORD,quora,googledns1
DOMAIN-KEYWORD,reddit,googledns1
DOMAIN-KEYWORD,wired,googledns1
DOMAIN-KEYWORD,bloomberg,googledns1
DOMAIN-KEYWORD,stackoverflow,googledns1
DOMAIN-KEYWORD,stackexchange,googledns1

[DnsHost]
# Static DNS map that functions in the same way as /etc/hosts.
localhost=127.0.0.1
# www.localnetwork.uop=127.0.0.1
# abcd.com=1.2.3.4

# [DnsClientIp]
# Client IP for EDNS Client Subnet extension, a single IP address.
# 115.239.211.92

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
