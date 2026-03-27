FROM alpine:3.22.3

RUN apk add --no-cache python3 py3-pip \
    && pip3 install --no-cache-dir requests --break-system-packages

WORKDIR /app

COPY tools/generate.py .

CMD [ "python3", "generate.py" ]
