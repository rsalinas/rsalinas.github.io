---
layout: post
title:  "Caching sudo privileges" 
date:   2015-11-03 21:00
categories: Linux sudo root
---

Sometimes we would like to "conserve" the sudo privilege for later using it, without executing as root the full script.

{% highlight console %}
function sudo_init  {
	! [ "${SUDO[0]:-}" == "" ] && return	
	coproc SUDO {
		sudo $SHELL -c 'while read cmd
			do
				sh -xc "$cmd" </dev/null >&2
				echo $? 
			done'
	}
}

function sudo_run  {
	for w in "$@"
	do 
		echo -n "'$w' " >&${SUDO[1]}
	done 
	echo >&${SUDO[1]}
	read -u ${SUDO[0]}
	return $REPLY
}
{% endhighlight %}

The usage is simple: as soon as we know that we will require sudo, we run sudo_init. We can run it multiple times without any effects.

Then, whenever we need to run something as root, we use "sudo_run" instead of sudo.


{% highlight console %}
if $SUDO_REQUIRED
then
	sudo_init
	if ! sudo_run true
	then
		die "Cannot run sudo"
	fi 	
fi

{% endhighlight %}

sudo_run respects multiple parameters given in the command line, as a normal sudo would, so that something this works:


{% highlight console %}
sudo_run echo "  a  "  "b c"
{% endhighlight %}

It uses bash's coprocesses.  The sudo command is launched in the background and this as soon as the main script ends, which makes the setup very secure.

The drawback is that the stdin and stdout of the called programs cannot be used, since it is used for sending the requests and responses, but all in all it is very useful.
