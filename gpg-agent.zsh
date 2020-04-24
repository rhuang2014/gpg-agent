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
}

other-agent-ssh() {
    export SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-$(launchctl getenv SSH_AUTH_SOCK)}
}

gpg-agent-ssh() {
    GNUPGCONFIG="${GNUPGHOME:-"${HOME}/.gnupg"}/gpg-agent.conf"
    [[ -r "${GNUPGCONFIG}" ]] &&\
        if command grep -q '^enable-ssh-support' "${GNUPGCONFIG}"; then
            export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-$(gpgconf --list-dirs agent-ssh-socket)}"
            unset SSH_AGENT_PID
        fi
        # update GPG-Agent TTY
        gpg-connect-agent updatestartuptty /bye &>/dev/null
}

gpg-agent-pinentry() {
    gpg-agent-stop
    for pid ($(pidof pinentry)) do
        kill "$pid"
    done
}

gpg-agent-status() {
    [[ ${GPG_AGENT} != "gpg-agent" ]] && other-agent-ssh
    command ${GPG_AGENT} --version >/dev/null || command ${GPG_AGENT} -version
    echo -e "\nPID: ${${$(pidof ${GPG_AGENT}):gs/ //}:-NOT_FOUND}, SOCK: ${SSH_AUTH_SOCK}\n"
    gpgconf --list-components
    [[ -n ${SSH_AUTH_SOCK} ]] && [[ ${GPG_AGENT} != "gpg-agent" ]] &&\
        eval ${${(s_-_)GPG_AGENT}[1]} stats
    return 0
}

gpg-agent-init() {
    AGENT_SOCK="$(gpgconf --list-dirs agent-socket)"
    if [[ ! -S ${AGENT_SOCK} ]]; then
        gpgconf --launch gpg-agent &>/dev/null
    fi
    # Set GPG_TTY so gpg-agent knows where to prompt.  See gpg-agent(1)
    export GPG_TTY="${TTY}"
    if [[ -n "$SSH_CONNECTION" ]]; then
        # Set PINENTRY_USER_DATA so pinentry-auto knows to present a text UI.
        export PINENTRY_USER_DATA='USE_CURSES=1'
    fi
    gpg-agent-ssh
    [[ ${GPG_AGENT} != "gpg-agent" ]] && other-agent-ssh
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
return 0
