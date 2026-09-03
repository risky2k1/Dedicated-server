[Unit]
Description=Conan Exiles Enhanced Dedicated Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=@RUN_USER@
Group=@RUN_GROUP@
WorkingDirectory=@SERVER_DIR@
EnvironmentFile=-@ENV_FILE@
Environment=LD_LIBRARY_PATH=@SERVER_DIR@/ConanSandbox/Binaries/Linux
ExecStart=@START_SCRIPT@
Restart=on-failure
RestartSec=15
# SIGINT lets Conan flush SQLite + rewrite ini cleanly
TimeoutStopSec=120
KillSignal=SIGINT
KillMode=control-group

[Install]
WantedBy=multi-user.target
