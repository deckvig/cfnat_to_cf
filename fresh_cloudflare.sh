#! /bin/sh

file=$1



API_TOKEN=$(printenv CF_TOKEN)
ZONE_ID=$(printenv CF_ZONE)
SUBDOMAIN=$(printenv CF_DOMAIN)
DNS_RECORD_ID=$(printenv CF_DNS_ID)

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
ip=""
while true
do
    echo "check ip in time interval, time: $(date)"
    echo "current ip is $ip"
    new_ip=$(grep '选择最佳连接' ${file} | tail -n 1 | awk '{print $5}' | cut -d ':' -f 1)
    if [ -z "$new_ip" ]; then
        echo "ip not found"
        sleep 60
        continue
    fi
    if [ "$new_ip" != "$ip" ]; then
        echo "update ip to $new_ip"
        test $(update_cloudflare_ip "$new_ip") && echo "update cloudflare ip success" && ip=$new_ip
        echo ""
    else
        echo "ip ${ip} not changed"
    fi
    # 定期清空日志
    truncate -s 0 ${file}
    sleep 60
done
