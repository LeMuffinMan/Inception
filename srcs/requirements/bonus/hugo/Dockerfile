FROM alpine:3.22.3

WORKDIR /var/hugo/muffin_site

COPY tools/init.sh /usr/local/bin/init.sh
COPY assets/avatar.jpg /tmp/avatar.jpg

RUN apk add --no-cache hugo git && \
    hugo new site /var/hugo/muffin_site --format yaml && \
    mkdir -p themes && \
    git clone https://github.com/adityatelange/hugo-PaperMod themes/PaperMod --depth=1 && \
    mkdir -p static/images/ && \
    cp /tmp/avatar.jpg static/images/avatar.jpg && \
    chmod +x /usr/local/bin/init.sh && \
    /usr/local/bin/init.sh && \
    hugo -b "/muffin_site" -D -d /var/www/html/muffin_site

EXPOSE 4200

CMD ["echo", "Hugo site is ready in /var/www/html/muffin_site"]
