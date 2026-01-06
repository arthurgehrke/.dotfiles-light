if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:${FPATH}
  autoload -Uz compinit
  compinit
fi

export PATH="$HOME/.nodenv/bin:$PATH"
eval "$(nodenv init -)"

autoload -U promptinit && promptinit

if [[ $- == *i* ]]; then
  stty -ixon <"$TTY" >"$TTY"
  function set_interrupt_key {
    if [ -t 0 ]; then
      stty intr "^k"
    fi
  }
  add-zsh-hook precmd set_interrupt_key
else
  stty intr "^k" 2>/dev/null || true
fi

CURRENT_HOST=$(hostname)
HIST_AIR="$HOME/.zsh_history_mac_air"
HIST_PRO="$HOME/.zsh_history_mac_pro"

if [[ "$CURRENT_HOST" == *"Air"* ]]; then
    export HISTFILE="$HIST_AIR"
    EXTRA_HIST="$HIST_PRO"
elif [[ "$CURRENT_HOST" == *"Pro"* ]]; then
    export HISTFILE="$HIST_PRO"
    EXTRA_HIST="$HIST_AIR"
else
    export HISTFILE="$HOME/.zsh_history"
fi

export HISTSIZE=500000000
export SAVEHIST=500000000
export HISTFILESIZE=50000000

setopt HISTIGNORESPACE
setopt BANG_HIST
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE 
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
setopt HIST_REDUCE_BLANKS
setopt INTERACTIVECOMMENTS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt IGNORE_EOF
setopt EXTENDED_HISTORY 

if [ -f "$EXTRA_HIST" ]; then
    fc -R "$EXTRA_HIST"
fi

source "$HOME"/.zaliases

setopt PUSHD_SILENT      
setopt AUTO_PUSHD       
setopt AUTOPARAMSLASH     
setopt LIST_AMBIGUOUS
setopt EXTENDED_GLOB 
setopt ALWAYS_TO_END   
setopt NO_BEEP
setopt COMPLETE_ALIASES
setopt CASE_PATHS
setopt COMPLETE_IN_WORD
setopt PROMPT_SUBST
setopt NO_HUP
setopt NO_NOMATCH

source "$(brew --prefix)"/share/zsh-history-substring-search/zsh-history-substring-search.zsh

bindkey -e '^l' forward-char
bindkey -e '^h' backward-char
bindkey -e '^e' forward-word
bindkey -e '^b' backward-word
bindkey -e '^d' delete-char
bindkey -e '^a' beginning-of-line
bindkey -e '^f' end-of-line
bindkey -e '^g' backward-kill-word
bindkey -e '^I' expand-or-complete-prefix

bindkey -e '^P' history-substring-search-up
bindkey -e '^N' history-substring-search-down

# Added by `nodenv init` on Mon Jan  5 00:17:06 -03 2026
eval "$(nodenv init - --no-rehash zsh)"
