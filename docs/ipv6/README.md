# IPv6 Network Setup in Our Lab

This document provides a clear guide on configuring and verifying IPv6 connectivity across our lab network. It covers the objectives, essential IPv6 concepts, and detailed configurations for key devices like the Mikrotik router, Huawei OLT, Layer 3 Switch, and Cisco Router. Our aim was to establish robust IPv6 routing and ensure seamless communication between all components.


## Core IPv6 Concepts

Before diving into configurations, let's clarify some key IPv6 address types relevant to our lab setup:

  * **Unique Local Addresses (ULAs):** These are IPv6 addresses designed for private networks, similar to IPv4's private IP ranges (e.g., 192.168.x.x). ULAs typically start with `fc00::/7` and are **not routable** on the public internet.
  * **IPv6 Documentation IPs:** These are specific address ranges, like `2001:db8::/32`, explicitly reserved for examples, technical documentation, and lab setups. They **should not be used** in production networks requiring internet connectivity. We utilize these for our lab environment.

-----

## Network Architecture Overview

Our lab comprises two primary private networks, both fully enabled for IPv6, with the **Mikrotik router acting as the central hub** for IPv6 advertisement and routing:

  * **Admin Network:** Corresponds to the IPv4 `192.168.88.0/24` subnet and the IPv6 `2001:db8:a:b::/64` subnet.
  * **Ether1 Network:** Corresponds to the IPv4 `192.168.50.0/27` subnet and the IPv6 `2001:db8:a:c::/64` subnet.

The Mikrotik is configured to advertise the prefixes for both networks, allowing devices within these segments to automatically obtain IPv6 addresses, primarily through **SLAAC (Stateless Address Autoconfiguration)**.

-----

## Device-Specific IPv6 Configurations

Here are the detailed IPv6 configurations applied to each key device in our lab.


### Mikrotik Router

The Mikrotik router is central to our IPv6 setup, acting as the gateway and advertising point for our lab networks.

**Current IPv6 Addresses:**
Here's a snapshot of the IPv6 addresses currently assigned to the Mikrotik interfaces:

```
[admin@MikroTik] > ipv6/address/print
Flags: D - DYNAMIC; G - GLOBAL, L - LINK-LOCAL
Columns: ADDRESS, INTERFACE, ADVERTISE
#   ADDRESS                             INTERFACE       ADVERTISE
;;; IPv6 for Admin Interface - Documentation
0   G 2001:db8:a:b::1/64                admin           yes
;;; IPv6 for Router Cisco and Faraday Interface - Documentation
1   G 2001:db8:a:c::1/64                ether1          yes
2 D ::1/128                             lo              no
3 DL fe80::c6ad:34ff:fed1:ff6b/64       admin           no
4 DL fe80::c6ad:34ff:fed1:ff72/64       fiberhome_gpon  no
5 DL fe80::cc97:deff:fe47:307d/64       bridge-wan      no
6 DL fe80::50f5:f9ff:fe9e:3459/64       bridge-huawei   no
7 DL fe80::c6ad:34ff:fed1:ff6a/64       ether1          no
```

The `ADVERTISE: yes` flag for global addresses indicates that the Mikrotik sends Router Advertisements, allowing devices to auto-configure their IPv6 addresses using SLAAC.

**IPv6 Settings:**
The Mikrotik is configured to **forward IPv6 packets**, effectively acting as an IPv6 router. To prevent conflicts and ensure it remains the authoritative router for its segments, `accept-router-advertisements` is disabled.

```
/ipv6 settings set accept-router-advertisements=no
```

**Adding Documentation IPv6 Addresses:**

For the **`admin` interface** (connected to the OLT and Admin Network):

```
/ipv6 address add address=2001:db8:a:b::1/64 interface=admin comment="IPv6 for Admin Interface - Documentation"
```

For the **`ether1` interface** (connected to the Cisco Router and Faraday):

```
/ipv6 address add address=2001:db8:a:c::1/64 interface=ether1 comment="IPv6 for Router Cisco and Faraday Interface - Documentation"
```

-----

### Layer 3 Switch

The Layer 3 Switch handles routing within its segments, providing IPv6 connectivity to connected devices.

**Enable IPv6 Unicast Routing:**
This command allows the switch to route IPv6 packets and forward discovery packets. It's crucial for its role as a router.

```
Switch(config)# ipv6 unicast-routing
```

**VLAN 1 Configuration:**

```
Switch(config)# interface vlan 1
Switch(config-if)# ipv6 enable
Switch(config-if)# ipv6 address 2001:db8:a:b::3/64
Switch(config-if)# no shutdown
```

**Default Gateway Configuration:**
A static default route ensures the Cisco Switch directs all IPv6 traffic destined for other networks towards the Mikrotik router (specifically, its admin interface).

```
SwitchAdmin(config)#ipv6 route ::/0 2001:db8:a:b::1
```

-----

### Cisco Router

The Cisco Router provides IPv6 connectivity to its connected segment, including Faraday.

**Enable IPv6 Routing:**
This command enables the global forwarding of IPv6 unicast packets on the router.

```
RouterAdmin(config)#ipv6 unicast-routing
```

**GigabitEthernet 0/0/1 Interface Configuration (Connected to Faraday):**
This interface is enabled for IPv6, using autoconfiguration (SLAAC) to obtain its address.

```
#While in the sub-interface of giga 0/0/1
ipv6 enable
ipv6 address autoconfig
no shutdown
```

**Static Route to Mikrotik (via Faraday):**
A static route is configured on the Cisco Router to ensure all traffic for unknown networks is directed through Faraday to the Mikrotik, which knows both lab IPv6 networks.

```
ipv6 route ::/0 2001:db8:a:c:6ccd:8cff:feaf:c89b
```

-----

## Summary of Assigned IPv6 Addresses

Here's a consolidated list of the documentation IPv6 addresses assigned to the main devices in our lab network (all using `/64` prefix lengths):

| Device                                    | IPv6 Address          |
| :---------------------------------------- | :-------------------- |
| **OLT Huawei** | `2001:db8:a:b::2`     |
| **Mikrotik - Admin Interface** | `2001:db8:a:b::1`     |
| **Layer 3 Switch** | `2001:db8:a:b::3`     |
| **Mikrotik - Ether1 Interface** | `2001:db8:a:c::1`     |
| **Cisco Router** | `2001:DB8:A:C:2B1:E3FF:FE21:45B1` |
| **Faraday** | `2001:db8:a:c:6ccd:8cff:feaf:c89b` |
| **CJ** | `2001:db8:a:b:d294:66ff:fe2b:b1f7` |

-----

## Troubleshooting Tip

If you encounter an interface that is down, you can typically bring it up using this command (common in Linux-based systems):

```bash
sudo ip link set <interface> up
```

-----
