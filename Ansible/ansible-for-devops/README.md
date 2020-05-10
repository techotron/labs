# Ansible for DevOps

## Chapter 1

`ansible -i inventory example -m ping -u ec2-user --private-key ~/.ssh/$SANDBOX_PRIVATE_KEY.pem`

## Chapter 2

## Useful commands

(Run within this directory)

||Task||Command||
|---|---|
|Initialise vagrantfile|`vagrant init`|
|Start VM using the vagrantfile|`vagrant up`|
|SSH onto vagrant box|`vagrant ssh`|
|Check SSH config for above|`vagrant ssh-config`|
|Shutdown VM|`vagrant halt`|
|Delete VM|`vagrant destroy`|
|Provision the playbook using the vagrant file (you can run this on a VM which is already running)|`vagrant provision`|

You can use an Ansible playbook that vagrant will use to provision a server. This is added to the `config.vm.provision` block

## Chapter 3

## Ad Hoc commands

The below is a collection of example ad-hoc commands. They don't fully setup a Django application but provide the high level steps needed to set this up if doing so via ad-hoc commands.

### Setting up 2 app servers with one DB server

**Note:** The order of the parameters in ansible don't matter.

Run ansible against all servers 

```bash
ansible -i inventory multi -a hostname
```

This will return the following for example:

```bash
92.168.60.5 | CHANGED | rc=0 >>
orc-app2.test
192.168.60.4 | CHANGED | rc=0 >>
orc-app1.test
192.168.60.6 | CHANGED | rc=0 >>
orc-db.test
```

The order of the servers in the response will change each time. The reason for this is that Ansbile will fork the process into five threads by default to run in parallel. You can override this with the `-f` flag, which will run the servers in series (rather than parallel) 

```bash
ansible -i inventory multi -a hostname -f 1
```

You can limit what command is sent to a server in a group. For example, the `app` group has 2 servers in it. We could send the following command to only 192.168.60.4 by using the `--limit` flag:

```bash
ansible -i inventory app -a "free -m" --limit "192.168.60.4"
# Example with wildcard
# ansibe -i inventory app -a "free -m" --limit "*.4"
```

**Note:** The `--limit` flag is a list type, so you could add multiple IPs here.

To return all everything about the server that Ansible has disovered: 

```bash
ansible -i inventory db -m setup
```

**Note:** The `-m` flag means "module". In this example we're using the setup module. If the module is specified, Ansible will default to the command module.

Install the NTP service on all servers:

```bash
ansible -i inventory multi -b -m yum -a "name=ntp state=present"
# More verbose command:
ansible -i inventory multi --become -m yum -a "name=ntp state=present"
```

**Note:** the `-b` flag means "become", as in "become sudo". This is because the default Ansible user doesn't have priviledges to install packages.
**Note:** the `-a` flag is for module arguments. The list of arguments a module has can be found in the docs online or by using `ansible-docs` (see below)

Start the NTP deamon on the servers:

```bash
ansible -i inventory multi -b -m service -a "name=ntpd status=started enabled=yes"
```

Example command which will update the time and date on the servers using the specified upstream NTP server:

``bash
ansible -i inventory multi -b -a "ntpdate -q 0.rhel.pool.ntp.org"
```

To check the docs via the CLI, use `ansible-doc`:

This example will open the docs for the service module

```bash
ansible-doc service
```

## Configure the Application Servers

Install packages:

```bash
ansible -i inventory app -b -m yum -a "name=MySQL-python state=present"
ansible -i inventory app -b -m yum -a "name=python-setuptools state=present"
ansible -i inventory app -b -m easy_install -a "name=djanjo<2 state=present"
```

Check Django is installed correctly:

```bash
ansible -i inventory app -a "python -c 'import django; print django.get_version()'"
```

Add `admin` group, using the `group` module:

```bash
ansible -i inventory app -b -m group -a "name=admin state=present"
```

**Note:** to remove it, you'd put `state=absent`

Create a user and add to `admin` group:

```bash
ansible -i inventory -b -m user -a "name=johndoe group=admin createhome=yes generate_ssh_keys=yes"
```

**Note:** to remove the user you'd add `state=absent remove=yes`

## Configure the Database Server

Install packages and add firewall rules

```bash
ansible -i inventory db -b -m yum -a "name=mariadb-server state=present"
ansible -i inventory db -b -m service -a "name=mariadb state=started enabled=yes"
ansible -i inventory db -b -a "iptables -F"
ansible -i inventory db -b -a "iptables -A INPUT -s 192.168.60.0/24 -p tcp -m tcp --dport 3306 -j ACCEPT"
```

Setup MariaDB

```bash
ansible -i inventory db -b -m yum -a "name=MySQL-python state=present"
ansible -i inventory db -b -m mysql_user -a "name=django host=% password=12345 priv=*.*:ALL state=present"
```

## Running operations in the background

You might want to do this if you're running a particularly long command (like an upgrade for example):

```bash
ansible -i inventory multi -b -B 3600 -P 0 -a "yum -y update"
```

**Note:** the `-B 3600` is the maximum time to let the background job run. `-P 0` number of seconds to wait between polling for job status updates. 0 == provide status and exit. 

While the background task is running, you can check on the status elsewhere, using the `async_status` module and the ansible_job_id from the previous command's output:

```bash
ansible -i inventory multi -b -m async_status -a "jid=423069903046.10330"
```

**Note:** this will fail amongst servers which that job id doesn't match. Use the --limit flag to specify the server that job id pertitent for.

You can also check the logs for ansible related entries:

```bash
# NOTE: This will fail because the command module (which is the default module) doesn't handle pipes and redirection
ansible -i inventory multi -b -a "tail /var/log/messages | grep ansible-command | wc -l"

# Use the "shell" module instead (not considered best practise):
ansible -i inventory multi -b -m shell -a "tail /var/log/messages | grep ansible-command | wc -l"
```

## Chapter 4

## Playbooks 

The inventory is an example of a simple AWS instance. This specific instance not longer exists.

There are 2 examples of playbooks. [playbook_just-commands.yml](./playbook_just-commands.yml) is a poor example of how to build a playbook by just using the command module. 

The better exmaple is [playbook.yml](./playbook.yml) which uses a variety of module to accomplish the same task.

**Note:** The playbook doesn't complete successfully because the http configuration files are blank and therefore the service fails to start in the last task but it serves as an example.

## Ansible-Playbook

Similar parameters for `ansible` exist for `ansible-playbook`. To play this book, run:

```bash
ansible-playbook -i inventory playbook.yml
```

You can run the playbook with "becomming" sudo via a parameter or by defining this in the script. (See playbook for example).

### Extra Variables

You can pass variables into the playbook with the `--extra-vars=VARS` parameter. It's a "key1=value1,key2=value2" format

## Running an inventory

You can run the following command to view an inventory of the instances in the inventory file:

```bash
ansible-inventory --list -i inventory
```

**Note:** This is useful for debugging inventory scripts.
