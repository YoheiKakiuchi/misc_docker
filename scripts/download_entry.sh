#!/bin/bash

if [ ! -e my_entrypoint.sh ]; then
    wget https://raw.githubusercontent.com/YoheiKakiuchi/misc_docker/master/my_entrypoint.sh
    chmod a+x my_entrypoint.sh
    sed -i -e 's@my_entryrc@entryrc@' my_entrypoint.sh
fi

if [ ! -e my_entryrc ]; then
    wget https://raw.githubusercontent.com/YoheiKakiuchi/misc_docker/master/my_entryrc
fi

if [ ! -e my_entrypoint_xserver.sh ]; then
    cp my_entrypoint.sh my_entrypoint_xserver.sh

    sed -i -e 's@source /entryrc@source /entryrc\
\
set +e\
until xset q; do\
    echo "wait Xserver for DISPLAY=${DISPLAY}"\
    sleep 3;\
done\
set -e@' my_entrypoint_xserver.sh
fi


