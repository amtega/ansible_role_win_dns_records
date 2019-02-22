# Ansible win_dns_record role

This is an [Ansible](http://www.ansible.com) role for management of Active Directory DNS records.

## Requirements

[Ansible 2.7.1+](http://docs.ansible.com/ansible/latest/intro_installation.html)

## Role Variables

None.  
Module `win_dns_record` variables are described in it's own documentation.

## Dependencies

None.

## Example Playbook

```yml
- name: win ping pdc
  win_ping:

- name: using amtega.win_dns_record role to import win_dns_record module
  import_role:
    name: amtega.win_dns_record


- name: "Add DNS A records: test1 => 1.2.3.4"
  win_dns_record:
    zone: domain.local
    name: test1
    value: 1.2.3.4
    type: A
```

## Testing

### Dependencies

Tests are based on vagrant virtual machines. You can setup vagrant engine
quickly using the role [amtega.vagrant_engine](https://galaxy.ansible.com/amtega/vagrant_engine).

### Execution

Once you have vagrant and virtualbox, you can run the tests with the following
commands:

```shell
$ cd amtega.amtega.win_dns_record/tests
$ ansible-playbook main.yml
$ ansible-playbook main.yml --diff
$ ansible-playbook main.yml --diff --check
```

## License

Copyright (C) 2019 AMTEGA - Xunta de Galicia

This role is free software: you can redistribute it and/or modify it under the terms of:

GNU General Public License version 3, or (at your option) any later version; or the European Union Public License, either Version 1.2 or – as soon they will be approved by the European Commission ­subsequent versions of the EUPL.

This role is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details or European Union Public License for more details.

## Author Information

- Daniel Sánchez Fábregas
