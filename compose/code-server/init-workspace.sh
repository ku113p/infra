#!/bin/bash
# Fix workspace ownership to match PUID/PGID on every start
chown "${PUID:-1000}:${PGID:-1000}" /workspace
