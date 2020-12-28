# pip3 install python-jose

#### Input
```python
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

# Encoded JWT with RS384 Signature
#### Input

```python
rsa_signing_jwk = get_signing_key("RS384.private.json")
jose.jwt.encode(
   jwt_claims,
   rsa_signing_jwk,
   algorithm='RS384',
   headers={"kid": rsa_signing_jwk["kid"]})
```

#### Output

   'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzM4NCIsImtpZCI6ImVlZTlmMTdhM2I1OThmZDg2NDE3YTk4MGI1OTFmYmU2In0.eyJpc3MiOiJiaWxpX21vbml0b3IiLCJzdWIiOiJiaWxpX21vbml0b3IiLCJhdWQiOiJodHRwczovL2F1dGhvcml6ZS5zbWFydGhlYWx0aGl0Lm9yZy90b2tlbiIsImV4cCI6MTQyMjU2ODg2MCwianRpIjoicmFuZG9tLW5vbi1yZXVzYWJsZS1qd3QtaWQtMTIzIn0.l2E3-ThahEzJ_gaAK8sosc9uk1uhsISmJfwQOtooEcgUiqkdMFdAUE7sr8uJN0fTmTP9TUxssFEAQnCOF8QjkMXngEruIL190YVlwukGgv1wazsi_ptI9euWAf2AjOXaPFm6t629vzdznzVu08EWglG70l41697AXnFK8GUWSBf_8WHrcmFwLD_EpO_BWMoEIGDOOLGjYzOB_eN6abpUo4GCB9gX2-U8IGXAU8UG-axLb35qY7Mczwq9oxM9Z0_IcC8R8TJJQFQXzazo9YZmqts6qQ4pRlsfKpy9IzyLzyR9KZyKLZalBytwkr2lW7QU3tC-xPrf43jQFVKr07f9dA'



# Encoded JWT with ES384 Signature
#### Input
```python
ec_signing_jwk  = get_signing_key("ES384.private.json")
jose.jwt.encode(
   jwt_claims,
   ec_signing_jwk,
   algorithm='ES384',
   headers={"kid": ec_signing_jwk["kid"]})
```


#### Output

   'eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzM4NCIsImtpZCI6ImNkNTIwMjExZTU2NjFkYmJhMjI1NmY2N2Y2ZDUzZjk3In0.eyJpc3MiOiJiaWxpX21vbml0b3IiLCJzdWIiOiJiaWxpX21vbml0b3IiLCJhdWQiOiJodHRwczovL2F1dGhvcml6ZS5zbWFydGhlYWx0aGl0Lm9yZy90b2tlbiIsImV4cCI6MTQyMjU2ODg2MCwianRpIjoicmFuZG9tLW5vbi1yZXVzYWJsZS1qd3QtaWQtMTIzIn0.ijKknbYSIa-Ja6qjErSDakTHaaI--k91ll0z-yRaKeiYESoVGV6Qq6_5FyDMGmX-WQPfs57pDgb1iQAE3YogxqufFDDEbirAijTg8GaUjHuahpdBUuVLe5pdZj7c7BsB'
