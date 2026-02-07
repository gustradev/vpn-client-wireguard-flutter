# PROFILE_FORMAT.md

## Schema Internal Profile GVPN

### Metadata
- id (uuid)
- name
- created_at, updated_at
- last_connected_at
- is_favorite
- config_raw_encrypted (atau split encrypted fields)

### Secret Fields (encrypted)
- interface_private_key
- peer_public_key
- preshared_key (optional)

### Non-secret
- address (CIDR)
- dns
- allowed_ips
- endpoint_host
- endpoint_port
- persistent_keepalive
- mtu (optional)

## Contoh JSON (internal)
```json
{
  "id": "c1a2b3d4-5678-90ab-cdef-1234567890ab",
  "name": "Office VPN",
  "created_at": "2026-02-08T10:00:00Z",
  "last_connected_at": "2026-02-08T12:00:00Z",
  "is_favorite": true,
  "config_raw_encrypted": "<encrypted>",
  "interface_private_key": "<encrypted>",
  "peer_public_key": "<encrypted>",
  "preshared_key": "<encrypted>",
  "address": "10.0.0.2/32",
  "dns": "8.8.8.8",
  "allowed_ips": "0.0.0.0/0",
  "endpoint_host": "vpn.example.com",
  "endpoint_port": 51820,
  "persistent_keepalive": 25,
  "mtu": 1420
}
```

---
Copyright 2026 GVPN Project
