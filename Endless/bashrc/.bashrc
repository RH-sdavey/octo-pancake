# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

PS_MACHINE_NAME="Endless"
PS_DEFAULT_IP=true


# cd
alias dc='cd'
alias ..='cd ..'
alias ...='cd ../../'

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


#fun
####alias section over####
#Set below line to change in terminal shell

source ~/.bashrc_zk_ps_addon
source /usr/share/git-core/contrib/completion/git-prompt.sh
source /etc/profile.d/bash_completion.sh

export PATH="~/bin:/usr/sbin:/sbin:${PATH}"




#(for hh, ctrl+r. improves history searching)  add this configuration to ~/.bashrc
# add hstr / dvorak if you wish
