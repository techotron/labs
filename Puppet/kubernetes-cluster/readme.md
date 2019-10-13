# kubernetes cluster (via puppet)

These are notes to document how to setup a local kubernetes cluster, using Puppet, onto a set of virtual box VMs.

## Requirements

The VMs were created with the same template image, then additional configuration as follows.

### Template Images

There are 2 images, Centos7 and Ubuntu18

### Ubuntu18 Puppet Template

- SSH generated on host, with the public key copied to `/root/.ssh/authorized_keys`
- Puppet repository downloaded and updated. Apt updated:

```bash
hostnamectl set-hostname ztemplate-puppet-ubuntu18
wget https://apt.puppetlabs.com/puppet6-release-bionic.deb
dpkg -i puppet6-release-bionic.deb
apt update
```

### Centos7 Puppet Template

- SSH generated on host, with the public key copied to `/root/.ssh/authorized_keys`
- Updated, added `epel-release`, installed wget and vim

```bash
hostnamectl set-hostname ztemplate-puppet-centos7
yum install -y epel-release
yum install wget -y
yum install vim -y
yum update -y

```

- Add Puppet repos and install puppet:

```bash
sudo rpm -Uvh https://yum.puppet.com/puppet6/puppet6-release-el-7.noarch.rpm
yum update -y
```

- Install the puppet agent

```bash
yum install puppet-agent -y
systemctl start puppet
systemctl enable puppet
```

- Add puppet master IP to /etc/hosts

```bash
192.168.86.71 master-puppet-01.lab localhost puppet
```

- Add puppet master to `/etc/puppetlabs/puppet/puppet.conf`:

```bash
[main]
server = puppet-master-01.lab
```

### Puppet Master

- Using the Ubuntu18 image (above)
- Set the hostname: `hostnamectl set-hostname master-puppet-01.lab`
- Configured the hosts file: `127.0.0.1   puppet-master-01.lab localhost puppet`
- Installed puppetserver: `apt-get install puppetserver pdk -y`
- Added the following to `/etc/puppetlabs/puppet/puppet.conf`

```bash
[main]
certname = puppet-master-01.lab

[master]
certname = puppet-master-01.lab
```

- Setup Puppet CA services: `/opt/puppetlabs/bin/puppetserver ca setup`
- Change memory limits for the server service: `vim /etc/default/puppetserver`

```bash
JAVA_ARGS="-Xms512m -Xmx512m -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger"
```

- Start and enable puppet server:

```bash
systemctl start puppetserver
systemctl enable puppetserver
```

**Note:** Running the first puppet server from the full path will add it to your bash profile but you'll need to reload this in order for it to apply (log out/back in or use `source`)

### Puppet Nodes

- Check the certificate fingerprint of the agent:

```bash
puppet agent --fingerprint
```

- Sign the node certificate (from the master):

```bash
puppetserver ca list

# Check the hostname of the cert you want to sign, then run
puppetserver ca sign --certname puppet-nginx-lb1.lab
```

## Setup Nginx Load Balancer

Now that we have a puppet master and our first agent configured and connected, we can start with configuring it.

### Create new module

- Create boilerplate files:

Run this in the `/etc/puppetlabs/code/environments/production/modules` directory

```bash
pdk new module nginx
```

From our new module directory ("nginx"), we need to create all the new classes we'll need. All the file contents are [here](./nginx-lb/manifests/). This creates more than just the .pp files (which I've yet to learn about) so need to create them using the pdk!

```bash
pdk new class install
pdk new class nginx # This is how we create the init.pp manifest, which ties all the other classes together.
pdk new class config
pdk new class service
pdk new class params
pdk new class vhosts
pdk new class loadbalancer
```

**Note:** TODO: Test copying the contents of ./nginx-lb to /etc/puppetlabs/code/environments/production/modules/nginx and seeing if this will work:

```bash
scp -i ~/.ssh/lab_key -r ./nginx-lb root@192.168.86.71:/etc/puppetlabs/code/environments/production/modules/nginx
```

Use the following to check configs:

```bash
puppet parser validate file.pp
```

Copy the contents of the .pp files [here](./nginx-lb/manifests/) to `/etc/puppetlabs/code/environments/production/modules/nginx/manifests/`

The Hiera config is located at different levels, the module one (typically in the module directory at ./data/common.yaml) and then in the node level in the production directory at ./data/nodes/SERVERNAME.yaml

For this configuration, the module level config is [here](./data/common.yaml)

The node level config is:

```yaml

---
nginx::vhosts_port: '8080'
nginx::vhosts_root: '/var/www'
nginx::vhosts_name: 'the-puppet-project.com'
nginx::vhosts_ensure: 'present'
nginx::lb_port: '80'
nginx::lb_name: 'lb'
nginx::lb_ensure: 'present'
```

#### General Server Configuration

- Install the firewall module (from the `production` directory) 

```bash
puppet module install puppetlabs-firewall
```

This will install the module plus any dependencies it has.

We'll now create a new module called "my_firewall" which will contain a couple of manifests to apply the firewall config we want:

(Just copy these to the master. Paths are relative to this readme)

```bash
scp -i ~/.ssh/lab_key -r ./my_firewall root@192.168.86.71:/etc/puppetlabs/code/environments/production/modules/
```

#### Last steps

Now we need to map our node to the configuration by using the `/etc/puppetlabs/code/environments/production/manifests/site.pp` file. Add the following to the site.pp (create it if it doesn't exist):

```bash
node 'puppet-nginx-lb1.lab' {
  class {'nginx':}
  class { 'firewall': }
  resources { 'firewall':
    purge => true,
  }
  
 Firewall {
     before  => Class['my_firewall::post'],
     require => Class['my_firewall::pre'],
 }

 class { ['my_firewall::pre', 'my_firewall::post']: }
  
}

```

Log onto the node and run the following to initiate a node to fetch and run config

```bash
puppet agent -t
```

#TODO: 

- [] CFN template to deploy puppet master
- [] CFN template to deploy puppet nodes