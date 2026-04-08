Justification de l'utilisation de tini avec vsftpd dans Docker
===============================================================

CONTEXTE
--------
vsftpd utilise une architecture multi-process : un processus parent privilégié gère
l'authentification et délègue chaque session FTP à un processus enfant non-privilégié
dans un chroot jail. C'est un choix de sécurité documenté par Red Hat :

  "vsftpd launches unprivileged child processes to handle incoming connections.
   Most interactions with FTP clients are handled by unprivileged child processes
   in a chroot jail."
  -- Red Hat Enterprise Linux 6 Deployment Guide
     https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/
     deployment_guide/s2-ftp-servers-vsftpd


PROBLÈME : exit 139 dans les logs Docker Compose
-------------------------------------------------
Exit code 139 = signal SIGSEGV (segmentation fault). Dans un container Docker,
quand un process enfant se termine sur SIGSEGV, Docker le rapporte comme exit 139 :

  "In Docker containers, when a Docker container terminates due to a SIGSEGV error,
   it throws exit code 139."
  -- Komodor, SIGSEGV: Linux Segmentation Fault | Signal 11, Exit code 139
     https://komodor.com/learn/sigsegv-segmentation-faults-signal-11-exit-code-139/

Le transfert se termine correctement (226 Transfer complete dans les logs vsftpd),
mais le processus enfant crashe lors de son cleanup après la session. Ce crash pollue
les logs et peut déclencher un restart on-failure.


CAUSE RACINE : PID 1 sans gestion des zombies
---------------------------------------------
Dans notre setup, init.sh (bash) est PID 1. Bash n'est pas conçu pour remplir le
rôle d'init : il n'appelle pas wait() sur les processus enfants qu'il ne connaît pas
directement. Quand le child vsftpd crashe, son exit code remonte incorrectement
comme exit du container.

C'est un problème général bien documenté pour les containers Docker :

  "When running applications inside Docker containers, many developers overlook a
   critical aspect of process management - the init process. Without a proper init
   process, your containers may fail to handle signals correctly, accumulate zombie
   processes, and behave unpredictably during shutdown."
  -- OneUptime Blog, How to Implement Docker Container Init Process
     https://oneuptime.com/blog/post/2026-01-30-docker-init-process/view


SOLUTION : tini comme PID 1
----------------------------
tini est un init minimaliste conçu spécifiquement pour les containers. Il fait une
seule chose : gérer proprement le cycle de vie des processus enfants.

  "All Tini does is spawn a single child (Tini is meant to be run in a container),
   and wait for it to exit all the while reaping zombies and performing signal
   forwarding."
  -- krallin/tini README, dépôt officiel
     https://github.com/krallin/tini/blob/master/README.md

  "By default, Tini needs to run as PID 1 so that it can reap zombies (by running
   as PID 1, zombies get re-parented to Tini)."
  -- krallin/tini README
     https://github.com/krallin/tini/blob/master/README.md

tini devient PID 1, récolte les exit codes de tous ses descendants, et ne propage
au kernel que l'exit code de son fils direct (vsftpd principal). Les crashs des
children de vsftpd sont absorbés silencieusement.


POURQUOI PAS LES ALTERNATIVES
------------------------------
- seccomp_sandbox=NO : nécessaire pour éviter le crash initial, mais insuffisant
  pour absorber les crashs de cleanup des children.

- one_process_model=YES : supprime le fork donc le problème, mais désactive
  l'authentification PAM. Non viable si l'auth locale est requise.
  (vsftpd man page : https://linux.die.net/man/5/vsftpd.conf)

- restart: no : masquerait le symptôme mais priverait le service de toute
  protection en cas de vrai crash.


IMPLÉMENTATION
--------------
Dockerfile :

    RUN apt update && apt install -y vsftpd iproute2 tini \
        && rm -rf /var/lib/apt/lists/*
    ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/init.sh"]

Note : Docker inclut tini nativement depuis la version 1.13 via le flag --init,
mais l'intégrer directement dans le Dockerfile garantit son usage indépendamment
du runtime Docker utilisé.

  "If you'd like more detail on why this is useful, review this issue discussion:
   What is advantage of Tini? NOTE: If you are using Docker 1.13 or greater,
   Tini is included in Docker itself."
  -- krallin/tini README
     https://github.com/krallin/tini/blob/master/README.md


RÉSULTAT
--------
Après l'ajout de tini : les transferts FTP fonctionnent normalement, l'auth est
préservée, les logs Docker Compose ne montrent plus d'exit 139 intempestifs, et
la politique restart: on-failure ne se déclenche plus sur les crashs de cleanup
des sessions.
