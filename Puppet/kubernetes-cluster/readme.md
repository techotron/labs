# kubernetes cluster (via puppet)

These are notes to document how to setup a local kubernetes cluster, using Puppet, onto a set of virtual box VMs.

## Requirements

The VMs were created with the same template image, then additional configuration as follows.

### Template Images

There are 2 images, Centos7 and Ubuntu18

### Ubuntu18 Puppet Template

- SSH generated on host, with the public key copied to `/root/.ssh/authorized_keys`

#TODO: install puppet packages (not server though)

### Centos7 Puppet Template

#TODO: create centos7 puppet template and run the below:

- Updated, added `epel-release`, installed wget and vim

```bash
yum update -y
yum install -y epel-release
yum install wget -y
yum install vim -y
```

- SSH keys generated on host, with the public key copied to `/root/.ssh/authorized_keys`
- Add Puppet repos and install puppet:

```bash
sudo rpm -Uvh https://yum.puppet.com/puppet6/puppet6-release-el-7.noarch.rpm
yum update -y
yum install puppet-agent -y
systemctl start puppet
systemctl enable puppet
```

### Puppet Master

#### VirtualBox VM Configuration

The master will need to download resources from the internet. In order to keep the environment portable (no matter what network I'm connect to at the time) I've added the nodes to the local vboxnet switch. For the master to connect to both these and the internet, it needs 2 interfaces.

- Cloned from Ubuntu18 image (new MAC address generated)
- Bridged Adapter (connected to whatever wifi/ethernet network you're connected to)
- Host-only Adapter

#### OS Configuration

#TODO: run the below on the master

- Using the Ubuntu18 image (above)
- Set the hostname: `hostnamectl set-hostname master-puppet-01.lab`
- Configured the hosts file: `127.0.0.1   master-puppet-01.lab localhost puppet`

### Puppet Nodes

#### VirtualBox VM Configuration

- Cloned from Template (new MAC address generated)
- Host-only Adapter



