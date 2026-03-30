#!/bin/sh

sed -i "s|^baseURL:.*|baseURL: ${DOMAIN}/muffin_site|" fichier.yaml

echo "Hugo site is deployed at ${DOMAIN}/muffin_site"
