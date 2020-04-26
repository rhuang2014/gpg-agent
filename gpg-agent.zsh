#!/usr/bin/env zsh
#
# zsh-gpg-agent
#
# version 1.0.0
# author: Roger huang
# url: https://github.com/rhuang/gpg-agent

# run the below command to set a different gpg-agent. i.e. YubiKey Smart Card agent
# if ! egrep -q '^[^#].*GPG_AGENT=' ~/.zshenv; then echo 'export GPG_AGENT="otheragent"' >> ~/.zshenv; fi
typeset -g GPG_AGENT="${GPG_AGENT:-gpg}-agent"
(( $+commands[${GPG_AGENT}] )) || return 1
typeset -g SSH_AUTH_SOCK AGENT_SOCK

gpg-agent-start() {
    gpg-agent-init
}

gpg-agent-stop() {
    if [[ -S $(gpgconf --list-dirs agent-socket) ]]; then
        gpgconf --kill gpg-agent
    fi
    gpg-agent-pinentry
}

gpg-agent-restart() {
    gpg-agent-stop
    sleep 1
    gpg-agent-start
}

gpg-agent-socket() {
    local ssh_auth_sock
    if [[ "${GPG_AGENT}" == "gpg-agent" ]]; then
        ssh_auth_sock=$(gpgconf --list-dirs agent-ssh-socket)
    else
        ssh_auth_sock=$(launchctl getenv SSH_AUTH_SOCK)
    fi
    [[ -n "${ssh_auth_sock}" ]] && SSH_AUTH_SOCK="${ssh_auth_sock}"
    unset ssh_auth_sock
}

gpg-agent-updatestartuptty() {
    # Set GPG_TTY so gpg-agent knows where to prompt.  See gpg-agent(1)
    export GPG_TTY="${TTY}"
    # update GPG-Agent TTY
    gpg-connect-agent -q updatestartuptty /bye &>/dev/null
    if [[ -n "$SSH_CONNECTION" ]]; then
        # Set PINENTRY_USER_DATA so pinentry-auto knows to present a text UI.
        export PINENTRY_USER_DATA='USE_CURSES=1'
    fi
}

gpg-agent-ssh() {
    GNUPGCONFIG="${GNUPGHOME:-"${HOME}/.gnupg"}/gpg-agent.conf"
    [[ -r "${GNUPGCONFIG}" ]] &&\
        if command grep -q '^enable-ssh-support' "${GNUPGCONFIG}"; then
            gpg-agent-socket
        fi
        gpg-agent-updatestartuptty
}

gpg-agent-pinentry() {
    for pid ($(pidof pinentry)) do
        kill "$pid"
    done
}

gpg-agent-hook() {
    autoload -U add-zsh-hook
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
    gpg-agent-updatestartuptty
}

gpg-agent-status() {
    [[ -n ${SSH_AUTH_SOCK} ]] || return
    command ${GPG_AGENT} -version 2>/dev/null || command ${GPG_AGENT} --version 2>/dev/null
    echo -e "\nPID: ${${$(pidof ${GPG_AGENT}):gs/ //}:-NOT_FOUND}, SOCK: ${SSH_AUTH_SOCK}\n"
    gpgconf --list-components 2>/dev/null
    eval ${${(s_-_)GPG_AGENT}[1]} stats 2>/dev/null
    return 0
}

gpg-agent-init() {
    AGENT_SOCK="$(gpgconf --list-dirs agent-socket)"
    if [[ ! -S ${AGENT_SOCK} ]]; then
        gpgconf --launch gpg-agent &>/dev/null
    fi
    gpg-agent-ssh
}

gpg-agent() {
    for act ($@); do
        case "${act}" in
            start) gpg-agent-start ;;
            stop) gpg-agent-stop ;;
            restart) gpg-agent-restart ;;
            ssh) gpg-agent-ssh ;;
            pinentry) gpg-agent-pinentry ;;
            *) gpg-agent-init ;;
        esac
        return
    done
    gpg-agent-init
}

gpg-agent "$@"
add-zsh-hook chpwd gpg-agent-hook
return 0
