# Ansible win_dns_records role

This is an [Ansible](http://www.ansible.com) role to manage of Active Directory DNS records.

## Role Variables

A list of all the default variables for this role is available in `defaults/main.yml`.

## Example Playbook

```yml
- name: Win ping pdc
  win_ping:

- include_role:
    name: amtega.win_dns_records
  vars:
    win_dns_records_fail_all_on_overwrite: yes
    win_dns_records:
        - name: test1
          zone: domain.local
          value: 1.2.3.4
          type: A
          ttl: 3600
        - name: 4
          zone: 3.2.1.in-addr.arpa.
          value: test1.domain.local.
          type: PTR
          ttl: 3600
```

## Testing

Tests are based on [molecule with vagrant virtual machines](https://molecule.readthedocs.io/en/latest/installation.html).

```shell
cd amtega.win_dns_records

molecule test --all
```

## License

Copyright (C) 2022 AMTEGA - Xunta de Galicia

This role is free software: you can redistribute it and/or modify it under the terms of:

GNU General Public License version 3, or (at your option) any later version; or the European Union Public License, either Version 1.2 or – as soon they will be approved by the European Commission ­subsequent versions of the EUPL.

This role is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details or European Union Public License for more details.

## Author Information

- Daniel Sánchez Fábregas
