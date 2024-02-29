Install OpenStack CLI:

  pipx install python-openstackclient --python $(which python3.11)
  pipx inject python-openstackclient gnureadline

openstack will look for a file called clouds.yaml in the following locations:
- Current Directory
- ~/.config/openstack
- /etc/openstack

The first file found wins.