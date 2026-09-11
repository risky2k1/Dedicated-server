[Unit]
Description=Valheim public status API (localhost)
After=network.target

[Service]
Type=simple
ExecStart=@STATUS_API@
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
