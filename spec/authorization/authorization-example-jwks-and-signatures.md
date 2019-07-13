```
#!/usr/bin/env python
# coding: utf-8
```
# In[1]:

```
# !pip3 install python-jose

import json
import jose.jwk
import jose.jwt
import jose.constants

def get_signing_key(filename):
    with open(filename) as private_key_file:
        signing_keyset = json.load(private_key_file)
        signing_key = [k for k in signing_keyset["keys"] if "sign" in k["key_ops"]][0]
        return signing_key

jwt_claims = {
  "iss": "bili_monitor",
  "sub": "bili_monitor",
  "aud": "https://authorize.smarthealthit.org/token",
  "exp": 1422568860,
  "jti": "random-non-reusable-jwt-id-123"
}
```

# In[2]:

```
print("\n# Encoded JWT with RS384 Signature")
rsa_signing_jwk = get_signing_key("RS384.private.json")
jose.jwt.encode(
    jwt_claims,
    rsa_signing_jwk,
    algorithm='RS384',
    headers={"kid": rsa_signing_jwk["kid"]})
```

# In[3]:

```
print("\n# Encoded JWT with ES384 Signature")
ec_signing_jwk  = get_signing_key("ES384.private.json")
jose.jwt.encode(
    jwt_claims,
    ec_signing_jwk,
    algorithm='ES384',
    headers={"kid": ec_signing_jwk["kid"]})
```
