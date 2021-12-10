#!/bin/sh

echo "Giving Portgresql time to start"
sleep 2s

exec /vaultwarden/vaultwarden "${@}"