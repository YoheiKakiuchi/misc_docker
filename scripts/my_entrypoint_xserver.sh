#!/bin/bash
set -e

source /entryrc

set +e
xset q
until xset q; do
    echo "wait Xserver for DISPLAY=${DISPLAY}"
    sleep 3;
done

set -e

exec "$@"
