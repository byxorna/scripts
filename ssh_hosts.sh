# bash completion to allow tab completion of hosts entries after ssh,scp,telnet,sshfs
# written Jul 1 2009
_ssh_hosts()
{
	local cur prev hosts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

# first we need to make a space seperated list of all users on this system
# note: on 128.252.120.2 grep in PATH sucks. use this one:  /usr/xpg4/bin/grep
# users=`cat /etc/passwd | grep home | cut -d: -f1`  # grep home for users
	hosts=`cat /etc/hosts | grep -v \# | grep -v -e '^$' | awk '{print $2}' | awk '{ str1=str1 $0 " "}END{ print str1 }'`
	if [[ ${cur} == * ]] ; then	#complete after user
		COMPREPLY=( $(compgen -W "${hosts}" -- ${cur}) )
		return 0
	fi
}
complete -F _ssh_hosts ssh
complete -F _ssh_hosts telnet
complete -F _ssh_hosts scp
complete -F _ssh_hosts sshfs
