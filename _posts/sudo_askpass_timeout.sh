
#! /bin/bash -eu   ## dash doesn't support read -s

## Default timeout is 60 seconds.
if read -s -t ${READ_TIMEOUT:-60} -p "$*"
then
    echo "$REPLY"
else
    echo "Timeout" >&2
    exit 1
fi
