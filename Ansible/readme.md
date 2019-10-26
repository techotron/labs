# Ansible

Agentless Config Manager

## Config

### Install Ansible (centos)

1. Add `epel-release` package
2. Install `ansible`

```bash
yum install -y epel-release
yum install -y ansible
```

### SSH Setup

1. Create a user that Ansible will use to authenticate with the servers. Typically, this is named `ansible` but can be whatever.
2. Add password for new user on the master and agent servers.
3. Add user to authenticate without needing password to sudoers
4. Create SSH key as that user on the master and copy to agent servers

```bash
[on master and agent]
useradd ansible
passwd ansible

[on master and agent]
sudo visudo
ansible         ALL=(ALL)       NOPASSWD: ALL

[on master]
sudo su ansible
ssh-keygen
ssh-copy-id <AGENT_HOSTNAME>
```

## Configure Ansible Master

1. Add agents to Ansible hosts file with an alias: `techotron2c ansible_host=<AGENT_HOSTNAME>`

## Working with AWS

