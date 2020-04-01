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

