
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
#dtests
alias dtvenv='cd /home/sdavey/Projects/dtests/ ; source ./venv/bin/activate ; cd ./dtests'
alias dtests='cd /home/sdavey/Projects/dtests/dtests/'
alias dt='cd /home/sdavey/Projects/dtests/dtests/'
alias doc='cd /home/sdavey/Projects/dtests-doc/'
alias rd='cd /home/sdavey/Projects/dtests-rundefs/'

#enmasse
alias masox='cd /opt/enmasse'
alias idea='~/Downloads/Intellij/idea-IC-172.4574.11/bin/idea.sh &'
alias mrg22_copy_systests='scp -r /opt/enmasse/systemtests/src/* root@10.37.144.46:/opt/enmasse/systemtests/src/'
alias find2jira='cd /opt/tools/ ; echo -e "\n ./github2jira <issue> --user <user>\n"'

# cd
alias dc='cd'
alias ..='cd ..'
alias ...='cd ../../../'

#alternatives and improvements to regular cli commands
alias install="sudo dnf install -y"
alias top="htop"
alias grp="ag"
alias ports='netstat -tulanp'
alias untar="tar -xf"
alias untargz="tar -xfz"
alias getip="ip -br -c -a"
alias os="cat /etc/*release*"

#top commands used in history
function topCmd() { history |    awk '{$1=""; print $0}' | sort | uniq -c | sort -rn | head $@;}
alias top10="topCmd"
alias top20="topCmd -20"
alias top50="topCmd -50"

#git
alias gg='git log --oneline --abbrev-commit --all --graph --decorate --color'

#java and other
alias jshell='/usr/lib/jvm/java-9-openjdk-9.0.4.11-6.fc28.x86_64/bin/jshell'

#fun
####alias section over####
#Set below line to change in terminal shell

PS_MACHINE_NAME="Endless"
PS_DEFAULT_IP=true

source ~/.bashrc_zk_ps_addon
source /usr/share/git-core/contrib/completion/git-prompt.sh
source /etc/profile.d/bash_completion.sh

export PATH="~/bin:/usr/sbin:/sbin:${PATH}"
##GIT TOKEN VARIABLE REMOVED HERE#################



#(for hh, ctrl+r. improves history searching)  add this configuration to ~/.bashrc
export HH_CONFIG=hicolor         # get more colors
shopt -s histappend              # append new history items to .bash_history
export HISTCONTROL=ignorespace   # leading space hides commands from history
export HISTFILESIZE=10000        # increase history file size (default is 500)
export HISTSIZE=${HISTFILESIZE}  # increase history size (default is 500)
export PROMPT_COMMAND="${PROMPT_COMMAND}; history -a; history -n"   # mem/file sync
# if this is interactive shell, then bind hh to Ctrl-r (for Vi mode check doc)
if [[ $- =~ .*i.* ]]; then bind '"\C-r": "\C-a hh -- \C-j"'; fi
