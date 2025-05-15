#! /bin/sh

file=$1

API_TOKEN=$(printenv CF_TOKEN)
ZONE_ID=$(printenv CF_ZONE)
SUBDOMAIN=$(printenv CF_DOMAIN)
DNS_RECORD_ID=$(printenv CF_DNS_ID)
TELEGRAM_BOT_TOKEN=$(printenv TELEGRAM_BOT_TOKEN)
TELEGRAM_CHAT_ID=$(printenv TELEGRAM_CHAT_ID)
INTERVAL=${INTERVAL:-90}

function update_cloudflare_ip() {
    new_ip=$1
    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${DNS_RECORD_ID}" \
     -H "Authorization: Bearer ${API_TOKEN}" \
     -H "Content-Type: application/json" \
     --data '{
       "type": "A",
       "name": "'${SUBDOMAIN}'",
       "content": "'${new_ip}'",
       "ttl": 120,
       "proxied": false
     }'
}

function send_message(){
    new_ip=$1
    curl --location "https://api.telegram.org/${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -H 'Content-Type: application/json' \
    --data '{
    "chat_id": "'${TELEGRAM_CHAT_ID}'",
    "text":"DNS 更新:\n\n域名: '${SUBDOMAIN}'\n新 IP:'${new_ip}'"
    }'
}

ip=""
while true
do
    echo "check ip in time interval, time: $(date)"
    echo "current ip is $ip"
    new_ip=$(tail -n 10 $file | grep '选择最佳连接'|tail -n 1 | awk '{print $5}' | cut -d ':' -f 1)
    if [ -z "$new_ip" ]; then
        echo "ip not found"
        sleep ${INTERVAL}
        continue
    fi
    if [ "$new_ip" != "$ip" ]; then
        echo "update ip to $new_ip"
        if update_cloudflare_ip "$new_ip"; then
            echo "update cloudflare ip success"
            ip=$new_ip
        else
            echo "update cloudflare ip failed"
        fi

        if send_message "$new_ip"; then
            echo "send message success"
        else
            echo "send message failed"
        fi
        echo ""
    else
        echo "ip ${ip} not changed"
    fi

    # 定期清空日志
    truncate -s 0 $file
    sleep ${INTERVAL}
done