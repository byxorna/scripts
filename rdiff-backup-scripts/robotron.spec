#### spec file for rdiff-backup
# disable globbing
set -f


hostname="robotron"
domain="nts.wustl.edu"
# see os-excludes for valid OS types
# i.e. linux, solaris, solaris-zones
os="linux"
# user to log in as (the user with the mass-command key in their .ssh/authorized_keys
user="root"
# backup root is the root of what you want to backup. this is usually '/'
# NOTE: if you choose to not use "/" as the backuproot, make sure you set the OS type to "none"
# as the backup root is where the rdiff-backup operates, and it will try to exclude things like /home/proc/*
# which doesnt exist (if your backuproot=/home)
backuproot='/'
# directories you want to specifically include
# may want to quote these
includedirs=( \
/backup \
/tmp \
/other/crap/* \
)
# any directory you want to exclude will go in here
# NOTE: excludes always come after includes, so includes take precedence
# i.e. --include /usr/local/bin, --exclude /usr/local will backup /usr/local/bin
# but nothing else in /usr/local
excludedirs=( \
/poop \
/dedoop \
)

# this is a space to pass in any custom arguments to rdiff-backup
# i.e. --exclude-other-filesystems to keep from falling into a mounted NFS share and backing that up
# or --exclude-special-files, --no-compression, etc
customargs='--exclude-other-filesystems'

# this is optional, but if you want to use a specific sshkey for a certain host, specify it here
#sshkey='/path/to/here'

# this option specifies the path to this hosts rdiff-backup binary, if it is not in the PATH
#binary=/usr/local/bin/rdiff-backup

#pythonpath="/usr/local/lib/python2.5/site-packages"

