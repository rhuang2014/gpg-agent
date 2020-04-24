gpg-agent (ssh-agent) zsh plugin
=======

The plugin starts `gpg-agent` automatically with ssh-agent support.

Settings
--------

To override the default `gpg-agent`, execute the below command to set the `GPG_AGENT` in your `~/.zshenv` config.

```zsh
if ! egrep -q '^[^#].*GPG_AGENT=' ~/.zshenv; then echo 'export GPG_AGENT="other_agent"' >> ~/.zshenv; fi
```

## Installation

### Using [zplug](https://github.com/b4b4r07/zplug)
Load gpg-agent as a plugin in your `.zshrc`

```shell
zplug "rhuang2014/gpg-agent"
```
