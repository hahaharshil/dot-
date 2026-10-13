#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Prompt: green user, cyan cwd
PS1='\[\e[1;32m\]\u\[\e[0m\] \[\e[1;36m\]\w\[\e[0m\] > '

# User-local binaries (claude, pipx, ...). Guarded so re-sourcing this file
# doesn't keep prepending the same entry.
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# Guarded so a fresh machine without it doesn't print "command not found"
# in every shell.
command -v fastfetch >/dev/null && fastfetch
