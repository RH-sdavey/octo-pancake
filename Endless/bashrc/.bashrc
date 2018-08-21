# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions


alias dc='cd'
alias dtvenv='cd /home/sdavey/Projects/dtests/ ; source ./venv/bin/activate ; cd ./dtests'
alias dtests='cd /home/sdavey/Projects/dtests/dtests/'
alias dt='cd /home/sdavey/Projects/dtests/dtests/'
alias doc='cd /home/sdavey/Projects/dtests-doc/'
alias rd='cd /home/sdavey/Projects/dtests-rundefs/'
alias idea='~/Downloads/Intellij/idea-IC-172.4574.11/bin/idea.sh &'

PS_MACHINE_NAME="$CHANGEME"
PS_DEFAULT_IP=true

source ~/.bashrc_zk_ps_addon
source /usr/share/git-core/contrib/completion/git-prompt.sh
source /etc/profile.d/bash_completion.sh

export PATH="~/bin:/usr/sbin:/sbin:${PATH}"




#(for hh, ctrl+r. improves history searching)  add this configuration to ~/.bashrc
export HH_CONFIG=hicolor         # get more colors
shopt -s histappend              # append new history items to .bash_history
export HISTCONTROL=ignorespace   # leading space hides commands from history
export HISTFILESIZE=10000        # increase history file size (default is 500)
export HISTSIZE=${HISTFILESIZE}  # increase history size (default is 500)
export PROMPT_COMMAND="${PROMPT_COMMAND}; history -a; history -n"   # mem/file sync
# if this is interactive shell, then bind hh to Ctrl-r (for Vi mode check doc)
if [[ $- =~ .*i.* ]]; then bind '"\C-r": "\C-a hh -- \C-j"'; fi

