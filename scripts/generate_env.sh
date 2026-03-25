#!/bin/bash

if [[ $EUID -eq 0 ]]; then
    echo "You must have sudo privilege to setup this project, to perform following operations:
        - Create folders, attribute it to other users or root, their deletion (make fclean) require sudo
        - Edit /etc/hosts to redirect 127.0.0.1 to your domain name instead of localhost"
    exit 1
fi

# trouver un .env dans srcs 
# verifier si il est vide
# le sourcer 
#
# On verifie avec -z si toutes les variables d'environnement sont set 
#
# pour chaque variable d'env on boucle tant qu'elle est vide sur un scanf 
# pour les mail on ajoute un ctrl

