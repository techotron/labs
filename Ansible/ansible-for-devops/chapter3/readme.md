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

## Running operations in the backgroup

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
