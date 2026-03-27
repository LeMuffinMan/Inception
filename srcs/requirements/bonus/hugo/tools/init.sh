#!/bin/sh

# mettre des variables
echo "baseURL: ${DOMAIN}/muffin_site
languageCode: en-us
title: MuffinSite
theme: ["PaperMod"]

params:
  profileMode:
    enabled: true
    title: "Muffin" # optional default will be site title
    subtitle: "Curious and passionate about systems and coding"
    imageUrl: "images/avatar.jpg" # optional
    imageTitle: "" # optional
    imageWidth: 220 # custom size
    imageHeight: 220 # custom size
    buttons:
      - name: Github
        url: "https://github.com/LeMuffinMan"
      - name: LinkedIn
        url: ""

menu:
  main:
    - name: "Accueil"
      url: "/"
      weight: 1
    - name: "Projets"
      url: "/projects/"
      weight: 2
    # - name: "Blog"
    #   url: "/posts/"
    #   weight: 3

caches:
  images:
    dir: :cacheDir/images" > hugo.yaml

mkdir -p content/projects/

echo "---
title: "Mes Projets"
draft: false
---
Bienvenue sur ma page de projets ! Voici quelques-uns de mes travaux récents." > content/projects/_index.md
