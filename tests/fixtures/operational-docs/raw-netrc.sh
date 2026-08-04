#!/usr/bin/env bash
printf 'machine %s\nlogin %s\npassword %s\n' \
  "$ESXI_HOST" "$ESXI_USER" "$ESXI_PASS" >"$NETRC_FILE"
