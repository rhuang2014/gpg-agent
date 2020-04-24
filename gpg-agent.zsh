#!/usr/bin/env zsh
#
# zsh-gpg-agent
#
# version 1.0.0
# author: Roger huang
# url: https://github.com/rhuang2014/gpg-agent

(( $+commands[gpg-agent] )) || return
typeset -g SSH_AUTH_SOCK AGENT_SOCK

gpg-agent-start() {
    gpg-agent-init
}

gpg-agent-stop() {
    if [[ -S $(gpgconf --list-dirs agent-socket) ]]; then
        gpgconf --kill gpg-agent
    fi
}

gpg-agent-ssh() {
    GNUPGCONFIG="${GNUPGHOME:-"${HOME}/.gnupg"}/gpg-agent.conf"
    [[ -r "${GNUPGCONFIG}" ]] &&\
        if command grep -q 'enable-ssh-support' "${GNUPGCONFIG}"; then
            export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
            unset SSH_AGENT_PID
        fi
        gpg-connect-agent updatestartuptty /bye &>/dev/null
}

gpg-agent-pinentry() {
    gpg-agent-stop
    for pid ($(pidof pinentry)) do
        kill "$pid"
    done
}

gpg-agent-status() {
    command gpg-agent --version
    echo -e "\nPID: ${$(pidof gpg-agent):-NOT_FOUND}, SOCK: ${SSH_AUTH_SOCK}\n"
    gpgconf --list-components
}

gpg-agent-init() {
    AGENT_SOCK="$(gpgconf --list-dirs agent-socket)"
    if [[ ! -S ${AGENT_SOCK} ]]; then
        gpgconf --launch gpg-agent &>/dev/null
    fi
    export GPG_TTY="${TTY}"
    gpg-agent-ssh
}

gpg-agent() {
    for act ($@); do
        case "${act}" in
            start) gpg-agent-start ;;
            stop) gpg-agent-stop ;;
            ssh) gpg-agent-ssh ;;
            kpa) gpg-agent-pinentry ;;
            *) gpg-agent-init ;;
        esac
        return
    done
    gpg-agent-init
}

gpg-agent "$@"
