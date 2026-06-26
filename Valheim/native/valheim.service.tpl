[Unit]
Description=Valheim Dedicated Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=@RUN_USER@
Group=@RUN_GROUP@
WorkingDirectory=@SERVER_DIR@
EnvironmentFile=-@ENV_FILE@
ExecStart=@START_SCRIPT@
Restart=on-failure
RestartSec=10
TimeoutStopSec=120
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
