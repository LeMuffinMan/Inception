#!/bin/sh

if [ -f /var/www/magic_site/index.html ]; then
    if [ -z "$GROQ_API_KEY" ]; then
        echo "No Groq api key found: using fallback page ..."
        cp fallback.html /var/www/html/magic_site/index.html
    elif ! python3 generate.py ]; then
        echo "MagicSite generation using API failed, using fallback page ..."
        cp fallback.html /var/www/html/magic_site/index.html
    fi
else
    echo "First build for llm-gen: using demo landing page"
    cp fallback.html /var/www/html/magic_site/index.html
fi
