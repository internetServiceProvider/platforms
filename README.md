
# 🧠 ISP Platform – I2T Lab Project

This repository contains the modular implementation of services required to deploy an ISP using the **i2t lab's GPON network**. All services are virtualized via **Vagrant + VirtualBox** on top of **Ubuntu Server**.

---

## 📁 Repository Structure

Each functionality or service must be organized into separate folders by purpose. By convention, all implementations live under the `features/` directory.

```
src/
├── dhcp/
│   └── Vagrantfile
│   └── kea-dhcp-config.json
│
├── core_virtualization/
│   └── Vagrantfile
│   └── setup.sh (Kubernetes, Grafana, Prometheus)
│
├── dns/
|   ├─config/
│   ├── zone_forward.json
│   ├── zone_reverse.json
│   |── zone_reverse_ipv6.json
|   ├── scripts/
│   |       └── setup_dns.sh
|   └── Vagrantfile
│
├── webserver/
│   └── Vagrantfile
│   └── index.html
│
├── firewall/
│   └── Vagrantfile
│   └── iptables_rules.sh
│
├── libre_qos/
│   └── Vagrantfile
│   └── setup_libreqos.sh
│
├── openwisp/
│   └── Vagrantfile
│   └── setup_openwisp.sh
```

---

## 🛠️ Implementation Rules

- All **code and configurations** must go inside their respective folder in `features/`.
- Each service must have its own `Vagrantfile` to enable independent deployment.
- Configuration files must be **well commented and documented**.
- Dependencies should be installed via `provision` blocks or shell scripts.
- All scripts must be **idempotent** — they should not break if run multiple times.
- Services must be deployable **individually or clustered**, depending on the project phase.

---

## 🚀 How to Use This Repository

```bash
# 1. Clone the repo:
git clone https://github.com/youruser/isp-infra.git
cd isp-infra

# 2. Go into the desired feature folder:
cd features/dhcpv4

# 3. Boot the VM:
vagrant up

# 4. To stop or destroy the VM:
vagrant halt
vagrant destroy
```

---

## 📦 Requirements

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)
- Linux/macOS/WSL host with repo cloned

---

## ✨ Naming Conventions

- IPs are allocated from the `192.168.20.0/24` range.
- Each VM must have a static IP defined in its `Vagrantfile`.
- Use consistent, clear names: `dns`, `core-k8s`, `lb`, `webserver`, etc.

---

## 📋 Project TODOs

- [x] Deploy DHCPv4
- [ ] Deploy core VM with Kubernetes and Grafana
- [x] Deploy DNS
- [ ] Deploy Load Balancer
- [ ] Deploy LibreQoS
- [ ] Deploy web server with QUIC
- [ ] Deploy OpenWISP
- [ ] Integrate monitoring with Zabbix or OpenWISP

---

> This repo should grow in layers — like an onion. Except it shouldn’t make future devs cry.
