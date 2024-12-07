FROM alpine:latest

RUN apk add --no-cache curl

COPY ./fresh_cloudflare.sh /usr/bin/fresh_cloudflare

RUN chmod +x /usr/bin/fresh_cloudflare