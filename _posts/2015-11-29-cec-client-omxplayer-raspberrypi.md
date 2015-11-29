---
layout: post
title:  "Using the televisor's remote command to control omxplayer in Raspberry Pi"
date:   2015-11-29 22:30
categories: raspberrypi
---

HDMI is not just a standard for transferring video.  At last they added some control flows, which lets different devices to communicate control commands.  For example, a televisor can ask the player to pause, by using the televisor's remote command, instead of having to use an extra remote command.

In Raspbian the package "cec-client" is available. This package lets us issue commands on other devices, and read the events happening in the CEC.

The challenges:

- Get the information from the remote command. cec-client provides these push/release events.
- Send this information to the running omxplayer.  We will use a tool called [terminal mixer](http://vicerveza.homeunix.net/~viric/soft/tm) (multiplex terminal). The idea es simple: we run "tm -wt omxplayer", and then at the same time we can send commands to it from anywhere else by means of "echo -n COMMAND | tm -t".  This tool is very easily installed by means of ./configure, make and make install.

This script uses a beautiful feature of bash and other shell interpreters, namely, the coprocesses.


{% highlight console %}
#! /bin/bash -eu

# This launches a coprocessor that will provide the CEC input data.
# "pow" will start the display at start. Then we wait while events arrive.
# Unless --line-buffered, information would come in big chunks,
# absolutely not realtime.
coproc cecclient { echo -e 'pow 0\nas'| cec-client |
	grep -e "key pressed" -e "key released" --line-buffered ; }

function cmd {
	# If there is no tm process available, we will start one
	[ ${tm_PID:-0} != 0 ] || coproc tm { tm -t;  }
	# Try to issue the command, but ignore any errors
	#   (errors will be common as the omxplayer ends).
	echo -ne "$1" >&"${tm[1]}" || echo -e "Cannot send command\a"
}

## Let's read from the coprocessor's output.
while read -u ${cecclient[0]} L
do
	echo $L    ## Debugging information
	## Key was pressed
	K=$(sed -n 's/.*key pressed: \([^ ]*\).*$/\1/p' <<< "$L" )
	## Key was released
	R=$(sed -n 's/.*key released: \([^ ]*\).*$/\1/p' <<< "$L" )

    ## Process presses for several keys
	case $K in
	select|pause) cmd ' ' ;;
	backward|rewind) cmd '\e[D' ;;
	forward|Fast) cmd '\e[C' ;;
	up) cmd '+' ;;
	down) cmd '-' ;;
	left) cmd i ;;
	right) cmd o ;;
	F1) cmd 'n' ;;
	F2) cmd 'm' ;;
	F3) cmd 's' ;;
	F4) cmd 'k' ;;
	exit)
		## We can reboot the RPi with the remote command.
		sudo reboot
	;;
	*) echo Unknown press: $K ;;
	esac

    ## Here we process releases for several keys
	case $R in
	## End the playing
	stop) cmd q ;;
	*) echo Unknown release: $R ;;
	esac
done
{% endhighlight %}

