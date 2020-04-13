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


