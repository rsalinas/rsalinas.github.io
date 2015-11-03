---
layout: post
title:  "Caching sudo privileges" 
date:   2015-01-17 12:17:31
categories: Linux sudo root
---

Sometimes we would like to "conserve" the sudo privilege for later using it, without executing as root the full script.

{% highlight shell %}
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


{% highlight shell %}
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


{% highlight shell %}
sudo_run echo "  a  "  "b c"
{% endhighlight %}
