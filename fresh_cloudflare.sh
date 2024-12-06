#! /bin/bash

file=$1

ip=""

API_TOKEN=$(printenv CF_TOKEN)
ZONE_ID=$(printenv CF_ZONE)
SUBDOMAIN=$(printenv CF_DOMAIN)
DNS_RECORD_ID=$(printenv CF_DNS_ID)

function update_cloudflare_ip() {
    new_ip=$1
    curl -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${DNS_RECORD_ID}" \
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

while true
do
    echo "check ip in time interval"
    date
    new_ip=$(grep '选择最佳连接' $1 | tail -n 1 | awk '{print $5}' | cut -d ':' -f 1)
    if [ -z "$new_ip" ]; then
        echo "ip not found"
        sleep 60
        continue
    fi
    if [ "$new_ip" != "$ip" ]; then
        ip=$new_ip
        echo "update ip to $ip"
        update_cloudflare_ip $ip
        echo "update cloudflare ip"
        echo ""
    else
        echo "ip not changed"
    fi
    sleep 60
done
