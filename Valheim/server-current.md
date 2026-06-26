root@phmtuns:/opt/Dedicated-server/Valheim/config# ls -lta
total 20
-rw-r--r-- 1 root root    0 Jun 26 11:39 adminlist.txt
drwxr-xr-x 8 root root 4096 Jun 26 11:39 ..
drwxr-xr-x 4 root root 4096 Jun 26 11:33 bepinex
drwxr-xr-x 4 root root 4096 Jun 26 11:32 worlds_local
drwxr-xr-x 5 root root 4096 Jun 26 11:29 .
drwxr-xr-x 2 root root 4096 Jun 26 11:14 backups
root@phmtuns:/opt/Dedicated-server/Valheim/config# cd bepinex/
root@phmtuns:/opt/Dedicated-server/Valheim/config/bepinex# ls -lta (có 2 chỗ config)
total 40
-rw-r--r-- 1 root root 5456 Jun 26 11:33 org.bepinex.plugins.servercharacters.cfg
drwxr-xr-x 4 root root 4096 Jun 26 11:33 .
-rw-r--r-- 1 root root 5792 Jun 26 11:33 BepInEx.cfg
-rw-r--r-- 1 root root 5592 Jun 26 11:33 BepInEx.cfg.default
drwxr-xr-x 2 root root 4096 Jun 26 11:33 plugins
drwxr-xr-x 2 root root 4096 Jun 26 11:29 config
drwxr-xr-x 5 root root 4096 Jun 26 11:29 ..
root@phmtuns:/opt/Dedicated-server/Valheim/config/bepinex# cd plugins/
root@phmtuns:/opt/Dedicated-server/Valheim/config/bepinex/plugins# ls -lta
total 1320
drwxr-xr-x 4 root root    4096 Jun 26 11:33 ..
-rw-r--r-- 1 root root 1343488 Jun 26 11:33 ServerCharacters.dll
-rw-r--r-- 1 root root       0 Jun 26 11:33 .gitkeep
drwxr-xr-x 2 root root    4096 Jun 26 11:33 .
root@phmtuns:/opt/Dedicated-server/Valheim/config/bepinex/plugins# cd ../config/
root@phmtuns:/opt/Dedicated-server/Valheim/config/bepinex/config# ls -lta
total 24
-rw-r--r-- 1 root root 5457 Jun 26 11:39 org.bepinex.plugins.servercharacters.cfg
-rw-r--r-- 1 root root 5796 Jun 26 11:39 BepInEx.cfg
drwxr-xr-x 4 root root 4096 Jun 26 11:33 ..
drwxr-xr-x 2 root root 4096 Jun 26 11:29 .
root@phmtuns:/opt/Dedicated-server/Valheim/config/bepinex/config# cd ..
root@phmtuns:/opt/Dedicated-server/Valheim/config/bepinex# cd ..
root@phmtuns:/opt/Dedicated-server/Valheim/config# cd worlds_local/
root@phmtuns:/opt/Dedicated-server/Valheim/config/worlds_local# ls -lta (World được scp sang, ko dùng được)
total 16656
drwxr-xr-x 2 root root    4096 Jun 26 11:39 worlds_local
-rw-r--r-- 1 root root     912 Jun 26 11:32 SuperSeed2_backup_auto-20260626084019.fwl
drwxr-xr-x 4 root root    4096 Jun 26 11:32 .
-rw-r--r-- 1 root root 4024960 Jun 26 11:32 SuperSeed2_backup_auto-20260626003143.db
-rw-r--r-- 1 root root     660 Jun 26 11:32 SuperSeed2_backup_auto-20260626003143.fwl
-rw-r--r-- 1 root root 4013224 Jun 26 11:32 SuperSeed2_backup_auto-20260626084019.db
-rw-r--r-- 1 root root 4013224 Jun 26 11:32 SuperSeed2.db.old
-rw-r--r-- 1 root root 4013224 Jun 26 11:32 SuperSeed2.db
-rw-r--r-- 1 root root     912 Jun 26 11:32 SuperSeed2.fwl.old
-rw-r--r-- 1 root root  933930 Jun 26 11:32 SuperSeed2_backup_auto-20260625134959.db
-rw-r--r-- 1 root root     912 Jun 26 11:32 SuperSeed2.fwl
-rw-r--r-- 1 root root      50 Jun 26 11:32 SuperSeed2_backup_auto-20260625134959.fwl
-rw-r--r-- 1 root root      42 Jun 26 11:29 permittedlist.txt
-rw-r--r-- 1 root root      40 Jun 26 11:29 bannedlist.txt
-rw-r--r-- 1 root root      39 Jun 26 11:29 adminlist.txt
drwxr-xr-x 2 root root    4096 Jun 26 11:29 characters_local
drwxr-xr-x 5 root root    4096 Jun 26 11:29 ..
root@phmtuns:/opt/Dedicated-server/Valheim/config/worlds_local# cd worlds_local/
root@phmtuns:/opt/Dedicated-server/Valheim/config/worlds_local/worlds_local# ls -lta (ko hiểu sao tạo world thì nó vào đây)
total 668
drwxr-xr-x 2 root root   4096 Jun 26 11:39 .
-rw-r--r-- 1 root root     50 Jun 26 11:39 Dedicated_backup_auto-20260626113921.fwl
-rw-r--r-- 1 root root     50 Jun 26 11:39 Dedicated.fwl
-rw-r--r-- 1 root root    661 Jun 26 11:39 SuperSeed2.fwl
-rw-r--r-- 1 root root 325437 Jun 26 11:39 SuperSeed2.db
drwxr-xr-x 4 root root   4096 Jun 26 11:32 ..
-rw-r--r-- 1 root root    409 Jun 26 11:32 SuperSeed2.fwl.old
-rw-r--r-- 1 root root 325437 Jun 26 11:32 SuperSeed2.db.old
-rw-r--r-- 1 root root     51 Jun 26 11:29 SuperSeed2_backup_auto-20260626112949.fwl
root@phmtuns:/opt/Dedicated-server/Valheim/config/worlds_local/worlds_local# cd ../characters_local/
root@phmtuns:/opt/Dedicated-server/Valheim/config/worlds_local/characters_local# ls -lta
total 8
drwxr-xr-x 4 root root 4096 Jun 26 11:32 ..
drwxr-xr-x 2 root root 4096 Jun 26 11:29 .