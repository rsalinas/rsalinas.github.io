function sudo_init  {
	! [ "${SUDO[0]:-}" == "" ] && return	
	coproc SUDO {
		sudo "$@" $SHELL -c 'while read cmd
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
