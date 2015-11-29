---
layout: post
title:  "Using the televisor's remote command to control omxplayer in Raspberry Pi"
date:   2015-11-29 22:30
categories: raspberrypi
---

I have a Raspberry Pi connected to my televisor (with HDMI) and despite having tried OpenElec as a media center, I have other services running on that machine and I am just too console-oriented to select with a graphical interface the media I want to play.  I use a laptop to start the films, but I was missing a way to pause/rewind the playing.  I finally solved it in a beautiful way, using HDMI CEC.

HDMI is not just a standard for transferring video.  At last they added control commands.  For example, a televisor can ask the player to pause, by using the televisor's remote command, instead of having to use an extra remote command.  The RPi can also ask the tv to switch on and to change to the relevant HDMI input.  Fantastic.

The challenges:

- Get the information from the remote command. cec-client provides these push/release events.  In Raspbian we can simply `apt-get install cec-client`.
- Send this information to the running `omxplayer`.  We will use a cool tool called [terminal mixer](http://vicerveza.homeunix.net/~viric/soft/tm) (multiplex terminal), written by Lluis Battle i Rosell. The idea es simple: we run `tm -wt omxplayer`, and then at the same time we can send commands to it from anywhere else by means of `echo -n COMMAND | tm -t`.  This tool is very easily installed by means of `./configure && make && make install`.

This script uses a beautiful feature of bash and other shell interpreters, namely, the *coprocesses*.

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

# Let's read from the coprocessor's output.
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

## Launching omxplayer

Of course we have to modify slightly `omxplayer` (which is a script) and prefix with `tm -wt` the invocation of `omxplayer.bin`.  That's all.

We could also  always run `tm -wt omxplayer ...` or have an alias for that.

## Configuring the televisor

You have to set up your televisor so that it will use CEC with your Raspberry Pi.

## Future work

A nice feature would be to just launch cec-client while we are running omxplayer.  This would save some processor time while we are not using it, and also it would not interfere in case we use other CEC clients in the RPi.  The challenge here is to cleanly kill this script (including its two coprocesses) when omxplayer ends.
