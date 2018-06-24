# cloud-init-pp
> cloud-init file proprocessor with file import and secret subsitution.

[cloud-init](http://cloudinit.readthedocs.io/en/latest/) is the defacto multi-distribution package that handles early initialization of a cloud instance.
`cloud-init-pp` provides extra flexibility by introducing a pre-processor in the deployment pipeline.

### Problems & Solution
`cloud-init` is designed to store everything in a single file, that is good to ensure consistency, however there are 3 problems:
1. If you have `write_files`, it is not convenient to alter its content.
2. If you put secret in it, it is not suitable to commit such file.
3. If you have multiple deployments which only differ in secrets, you might have large portion of duplicate code which is error prone to maintain.

The pre-processor allow you to move secrets and file out of the cloud-init definition, and allow different deployments share some common files with import.

### Example
###### `cloud-init.in`
```
#cloud-config

# This file just like usual cloud-init

write_files:
  - path: /usr/local/deploy-app/.env
    permissions: '0600'
    content: @.env
  - path: /usr/local/deploy-app/startup.sh
    permissions: '0700'
    content: @startup.sh
  - path: /usr/local/deploy-app/dummy.txt
    permissions: '0600'
    content: |
        Dummy file defined in old fashioned way

runcmd:
  - chown -R deployuser:deployuser /usr/local/deploy-app/
  - chmod 0700 /usr/local/deploy-app/
  - /usr/local/deploy-app/startup.sh
```
###### `.env`
```
SECRET=abc
FOO=bar
```
###### `startup.sh`
```
#!/bin/sh
echo Hello World!
```
##### Result
###### `cloud-init.txt`
```
#cloud-config

# This file just like usual cloud-init

write_files:
  - path: /usr/local/deploy-app/.env
    permissions: '0600'
    encoding: b64
    content: U0VDUkVUPWFiYw0KRk9PPWJhcg==
  - path: /usr/local/deploy-app/startup.sh
    permissions: '0700'
    encoding: b64
    content: IyEvYmluL3NoDQplY2hvIEhlbGxvIFdvcmxkIQ==
  - path: /usr/local/deploy-app/dummy.txt
    permissions: '0600'
    content: |
        Dummy file defined in old fashioned way

runcmd:
  - chown -R deployuser:deployuser /usr/local/deploy-app/
  - chmod 0700 /usr/local/deploy-app/
  - /usr/local/deploy-app/startup.sh
```
