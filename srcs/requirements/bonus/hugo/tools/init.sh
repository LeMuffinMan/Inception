#!/bin/sh

cd /var/hugo/muffin_site

cat > hugo.yaml << EOF
baseURL: "${DOMAIN}/muffin_site"
languageCode: en-us
title: MuffinSite
theme: ["PaperMod"]
params:
  profileMode:
    enabled: true
    title: "Muffin"
    subtitle: "Curious and passionate about systems and coding"
    imageUrl: "images/avatar.jpg"
    imageTitle: ""
    imageWidth: 220
    imageHeight: 220
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
caches:
  images:
    dir: :cacheDir/images
EOF

mkdir -p content
cat > content/_index.md << 'EOF'
---
title: "Accueil"
draft: false
---
EOF

mkdir -p content/projects
cat > content/projects/_index.md << 'EOF'
---
title: "Mes Projets"
layout: "list"
draft: false
---
Bienvenue sur ma page de projets !
EOF

cat > content/projects/inception.md << 'EOF'
---
title: "Inception"
date: 2024-01-01
description: "Déploiement de services via Docker Compose"
tags: ["docker", "devops"]
draft: false
---
Description du projet Inception.
EOF
