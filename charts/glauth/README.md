GLAuth: LDAP authentication server
==============

For me information please visit the official github repository [GLAuth](https://github.com/glauth/glauth).

## Prerequisites

- Kubernetes 1.25+
- Helm 3.0+

## Installing

Add the desired configuration under `app.config` in the Helm `values.yaml`. 
Here's a sample config with hardcoded users and groups:
```toml
[backend]
  datastore = "config"
  nameformat = "cn"
  groupformat = "ou"
  baseDN = "dc=demo,dc=io"

[behaviors]
  IgnoreCapabilities = false
  LimitFailedBinds = false

[ldap]
  enabled = true
  listen = "0.0.0.0:3893"
[ldaps]
  enabled = false
  listen = "0.0.0.0:3894"
  cert = "/app/config/ssl/glauth-ca-cert.pem"
  key = "/app/config/ssl/glauth-ca-key.pem"
[api]
  enabled = false
  internals = true
  listen = "0.0.0.0:5555"

[[groups]]
  name = "users"
  gidnumber = 4401

[[users]]
  name = "testuser1"
  uidnumber = 4001
  primarygroup = 4401
  passsha256 = "00a082620a12245988ee6ef6d61a561c009e0bbd033b40604b96c199f28c42b6"
[[users.capabilities]]
  action = "search"
  object = "ou=users,dc=demo,dc=io"
```

Here is how you can generate a SHA256 password hash.
```bash
#!/bin/bash
password=$(pwgen -n1 32)
echo "Passwd: ${password}"
# Generate SHA-256 hash of the password
pass_sha256=$(echo -n "${password}" | openssl dgst -sha256 | sed 's/^.* //')
echo "Sha256 ${pass_sha256}"
```
