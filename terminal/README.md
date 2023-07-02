## Truecolor Detection
https://github.com/termstandard/colors#truecolor-detection

ADD `COLORTERM` and `TERM` to:
- `SendEnv` list in `/etc/ssh/ssh_config` on ssh clients
- `AcceptEnv` list in `/etc/ssh/sshd_config` on ssh servers
- `env_keep` list in `/etc/sudoers`

## etc
https://github.com/stayradiated/termcolors