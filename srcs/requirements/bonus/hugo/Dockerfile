FROM alpine:3.22.3

WORKDIR /var/hugo/muffin_site

COPY conf /tmp/conf
COPY --chmod=755 tools/init.sh /usr/local/bin/init.sh

RUN apk add --no-cache hugo git && \
    hugo new site /var/hugo/muffin_site --format yaml && \
    mkdir -p themes && \
    git clone https://github.com/adityatelange/hugo-PaperMod themes/PaperMod --depth=1 && \
    mkdir -p static/images/ && \
    cp -r /tmp/conf/* . && \
    cp avatar.jpg static/images/avatar.jpg && \
    hugo -b "/muffin_site" -D -d /var/www/html/muffin_site && \
    rm -rf /tmp/*

EXPOSE 4200

CMD ["/usr/local/bin/init.sh"]
