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
title: "My Projetcs"
layout: "list"
draft: false
---
EOF

cat > content/projects/inception.md << 'EOF'
---
title: "Inception"
date: 2026-03-26
description: "Automated deployment of multi-service applications with Docker Compose"
tags: ["docker", "devops"]
draft: false
---
Inception is a project focused on automating the deployment of complex service stacks using Docker Compose. It demonstrates how to efficiently manage services such as MariaDB, Nginx, and WordPress in a reproducible environment.

Stack: MariaDB, Nginx, WordPress
EOF

cat > content/projects/chessgame.md << 'EOF'
---
title: "ChessGame"
date: 2026-03-26
description: "A browser-based chess application built with Rust and WebAssembly"
tags: ["rust", "wasm", "webdev"]
draft: false
---
ChessGame is an interactive chess application built with Rust and compiled to WebAssembly for high performance in the browser. It showcases Rust's capabilities in front-end development and WASM integration.
EOF

cat > content/projects/magic_site.md << 'EOF'
---
title: "MagicSite"
date: 2026-03-26
description: "Static website generation powered by AI"
tags: ["static site", "ai", "automation"]
draft: false
---
MagicSite leverages AI to automatically generate static web pages. This project explores how modern language models can assist in web development, reducing manual work and improving content creation efficiency.
EOF
