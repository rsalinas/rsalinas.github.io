---
layout: post
title:  "sudo with a password timeout"
date:   2015-11-05 20:00
categories: linux security
---

sudo-askpass-timeout.sh:

{% highlight console %}
#! /bin/bash -eu 

# "read" will not reset the terminal echo mode if it is canceled. Let's save/restore the tty status.
stty_orig=`stty -g`
trap 'stty "$stty_orig"' EXIT

## Default timeout is 60 seconds.
if read -s -t ${READ_TIMEOUT:-60} -p "$*"
then
	echo "$REPLY"
else
	echo "Timeout" >&2
	exit 1
fi
{% endhighlight %}


sudo-timeout.sh:

{% highlight console %}
#! /bin/bash -eu

## Syntax:  sudo-timeout.sh [-t timeout_in_seconds] <sudo arguments>
## Example:  sudo-timeout.sh -t 60 apt-get update

export SUDO_ASKPASS="$(dirname "$0")/sudo-askpass-timeout.sh"
export READ_TIMEOUT=60
if [ $# -ge 3  ] && [ "$1" = "-t" ]
then 
	shift
	READ_TIMEOUT=$1
	shift
fi
exec sudo -A "$@"
{% endhighlight %}

Usage: sudo-timeout.sh [-t TIMEOUT] <cmd...>
