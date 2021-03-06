#!/bin/ash
TEST_URL="https://baidu.com"
UA_XL="User-Agent: swjsq/0.0.1"

if [ ! -z "`wget --no-check-certificate -O - $TEST_URL 2>&1|grep "100%"`" ]; then
   HTTP_REQ="wget -q --no-check-certificate -O - "
   POST_ARG="--post-data="
else
   command -v curl >/dev/null 2>&1 && curl -kI $TEST_URL >/dev/null 2>&1 || { echo >&2 "Xunlei-FastD1ck cannot find wget or curl installed with https(ssl) enabled in this system."; exit 1; }
   HTTP_REQ="curl -ks"
   POST_ARG="--data "
fi

uid=826860958
pwd=wasd19991124
nic=eth0
peerid=000000000000004V
uid_orig=$uid

last_login_xunlei=0
login_xunlei_intv=600

day_of_month_orig=`date +%d`
orig_day_of_month=`echo $day_of_month_orig|grep -oE "[1-9]{1,2}"`

#portal=`$HTTP_REQ http://api.portal.swjsq.vip.xunlei.com:82/v2/queryportal`
#portal_ip=`echo $portal|grep -oE '([0-9]{1,3}[\.]){3}[0-9]{1,3}'`
#portal_port_temp=`echo $portal|grep -oE "port...[0-9]{1,5}"`
#portal_port=`echo $portal_port_temp|grep -oE '[0-9]{1,5}'`
portal_ip=47.101.173.9
portal_port=12180
portal_up_ip=153.37.208.185
portal_up_port=81

if [ -z "$portal_ip" ]; then
    sleep 30
    portal=`$HTTP_REQ http://api.portal.swjsq.vip.xunlei.com:81/v2/queryportal`
    portal_ip=`echo $portal|grep -oE '([0-9]{1,3}[\.]){3}[0-9]{1,3}'`
    portal_port_temp=`echo $portal|grep -oE "port...[0-9]{1,5}"`
    portal_port=`echo $portal_port_temp|grep -oE '[0-9]{1,5}'`
    if [ -z "$portal_ip" ]; then
        portal_ip="119.147.41.210"
        portal_port=12180
    fi
fi

log () {
    echo `date +%X 2>/dev/null` $@
}

api_url="http://$portal_ip:$portal_port/v2"
api_up_url="http://$portal_up_ip:$portal_up_port/v2"

do_down_accel=1
do_up_accel=0

i=100
while true; do
    if test $i -ge 100; then
        tmstmp=`date "+%s"`
        let slp=login_xunlei_intv-tmstmp+last_login_xunlei
        if test $slp -ge 0; then
            sleep $slp
        fi
        last_login_xunlei=$tmstmp

        if [ ! -z "$loginkey" ]; then
            log "renew xunlei"
            ret=`$HTTP_REQ https://mobile-login.xunlei.com:443/loginkey $POST_ARG"{\"protocolVersion\": \"200\", \"sequenceNo\": \"1000001\", \"platformVersion\": \"2\", \"sdkVersion\": \"177662\", \"peerID\": \"000000000000004V\", \"businessType\": \"68\", \"clientVersion\": \"2.4.1.3\", \"devicesign\": \"div101.e0ebf3ea51d994d644fe189ace3773f5570646ea5015558e613e475ad4d09fab\", \"isCompressed\": \"0\", \"userName\": \"826860958\", \"appName\": \"ANDROID-com.xunlei.vip.swjsq\", \"deviceModel\": \"R1\", \"deviceName\": \"SmallRice R1\", \"OSVersion\": \"5.0.1\", \"loginKey\": \"$loginkey\"}" --header "$UA_XL"`
            error_code=`echo $ret|grep -oE "errorCode...[0-9]+"|grep -oE "[0-9]+"`
            if [[ -z $error_code || $error_code -ne 0 ]]; then
                log "renew error code $error_code"
            fi
            session_temp=`echo $ret|grep -oE "sessionID...[A-F,0-9]{32}"`
            session=`echo $session_temp|grep -oE "[A-F,0-9]{32}"`
            if [ -z "$session" ]; then
                log "renew session is empty"
                sleep 60
            else
                log "session is $session"
            fi
        fi

        if [ -z "$session" ]; then
            log "login xunlei"
            ret=`$HTTP_REQ https://mobile-login.xunlei.com:443/login $POST_ARG"{\"protocolVersion\": \"200\", \"sequenceNo\": \"1000001\", \"platformVersion\": \"2\", \"sdkVersion\": \"177662\", \"peerID\": \"000000000000004V\", \"businessType\": \"68\", \"clientVersion\": \"2.4.1.3\", \"devicesign\": \"div101.e0ebf3ea51d994d644fe189ace3773f5570646ea5015558e613e475ad4d09fab\", \"isCompressed\": \"0\", \"userName\": \"17667936660\", \"passWord\": \"wasd19991124\", \"sessionID\": \"\", \"verifyKey\": \"\", \"verifyCode\": \"\", \"appName\": \"ANDROID-com.xunlei.vip.swjsq\", \"deviceModel\": \"R1\", \"deviceName\": \"SmallRice R1\", \"OSVersion\": \"5.0.1\"}" --header "$UA_XL"`
            session_temp=`echo $ret|grep -oE "sessionID...[A-F,0-9]{32}"`
            session=`echo $session_temp|grep -oE "[A-F,0-9]{32}"`
            uid_temp=`echo $ret|grep -oE "userID...[0-9]+"`
            uid=`echo $uid_temp|grep -oE "[0-9]+"`
            if [ -z "$session" ]; then
                log "login session is empty"
                uid=$uid_orig
            else
                log "session is $session"
            fi

            if [ -z "$uid" ]; then
                #echo "uid is empty"
                uid=$uid_orig
            else
                log "uid is $uid"
            fi
        fi

        if [ -z "$session" ]; then
            sleep 600
            continue
        fi

        loginkey=`echo $ret|grep -oE "lk...[a-f,0-9,\.]{96}"`
        i=18
    fi

    if test $i -eq 18; then
        # TODO: is it needed to recover before upgrade?
        _ts=`date +%s`0000
        if test $do_down_accel -eq 1; then
            log "upgrade downstream"
            ret=`$HTTP_REQ "$api_url/upgrade?peerid=$peerid&userid=$uid&sessionid=$session&user_type=1&client_type=android-swjsq-2.4.1.3&time_and=$_ts&client_version=androidswjsq-2.4.1.3&os=android-5.0.1.24R1&dial_account=053400598416"`
            if [ ! -z "`echo $ret|grep "client request too frequent"`" ]; then
                log "upgrade request too frequent, retrying in 1 minute"
                sleep 60
                continue
            fi
        fi
        if test $do_up_accel -eq 1; then
            log "upgrade upstream"
            ret=`$HTTP_REQ "$api_up_url/upgrade?peerid=$peerid&userid=$uid&sessionid=$session&user_type=1&client_type=android-uplink-2.4.1.3&time_and=$_ts&client_version=androiduplink-2.4.1.3&os=android-5.0.1.24R1&dial_account=053400598416"`
            if [ ! -z "`echo $ret|grep "client request too frequent"`" ]; then
                log "upgrade request too frequent, retrying in 1 minute"
                sleep 60
                continue
            fi
        fi
        i=1
        sleep 590
        continue
    fi

    sleep 1
    day_of_month_orig=`date +%d`
    day_of_month=`echo $day_of_month_orig|grep -oE "[1-9]{1,2}"`
    if [[ -z $orig_day_of_month || $day_of_month -ne $orig_day_of_month ]]; then
        log "recover"
        orig_day_of_month=$day_of_month
        _ts=`date +%s`0000
        if test $do_down_accel -eq 1; then
            $HTTP_REQ "$api_url/recover?peerid=$peerid&userid=$uid&sessionid=$session&client_type=android-swjsq-2.4.1.3&time_and=$_ts&client_version=androidswjsq-2.4.1.3&os=android-5.0.1.24R1&dial_account=053400598416"
        fi
        if test $do_up_accel -eq 1; then
            $HTTP_REQ "$api_up_url/recover?peerid=$peerid&userid=$uid&sessionid=$session&client_type=android-uplink-2.4.1.3&time_and=$_ts&client_version=androiduplink-2.4.1.3&os=android-5.0.1.24R1&dial_account=053400598416"
        fi
        sleep 5
        i=100
        continue
    fi


    log "keepalive"
    _ts=`date +%s`0000
    if test $do_down_accel -eq 1; then
        ret=`$HTTP_REQ "$api_url/keepalive?peerid=$peerid&userid=$uid&sessionid=$session&client_type=android-swjsq-2.4.1.3&time_and=$_ts&client_version=androidswjsq-2.4.1.3&os=android-5.0.1.24R1&dial_account=053400598416"`
        if [[ -z $ret ]]; then
            log "keepalive downstream error, re-upgrade" 
            sleep 60
            i=18
            continue
        elif [ ! -z "`echo $ret|grep "not exist channel"`" ]; then
            log "keepalive downstream not exist channel, re-login" 
            i=100
            continue
        elif  [ ! -z "`echo $ret|grep "user not has business property"`" ]; then
            log "membership expired? disabling fastdick"
            do_down_accel=0
        elif [ ! -z "`echo $ret|grep "client request too frequent"`" ]; then
            log "keepalive downstream request too frequent, retrying in 1 minute"
            sleep 60
            continue
        fi
    fi
    if test $do_up_accel -eq 1; then
        ret=`$HTTP_REQ "$api_up_url/keepalive?peerid=$peerid&userid=$uid&sessionid=$session&client_type=android-uplink-2.4.1.3&time_and=$_ts&client_version=androiduplink-2.4.1.3&os=android-5.0.1.24R1&dial_account=053400598416"`
        if [[ -z $ret ]]; then
            log "keepalive upstream error, re-upgrade" 
            sleep 60
            i=18
            continue
        elif [ ! -z "`echo $ret|grep "not exist channel"`" ]; then
            log "keepalive upstream not exist channel, re-login" 
            i=100
            continue
        elif [ ! -z "`echo $ret|grep "user not has business property"`" ]; then
            log "membership expired? disabling upstream acceleration"
            do_up_accel=0
        elif [ ! -z "`echo $ret|grep "client request too frequent"`" ]; then
            log "keepalive request too frequent, retrying in 1 minute"
            sleep 60
            continue
        fi
    fi
    
    if test $i -ne 100; then
        let i=i+1
        sleep 590
    fi
done
