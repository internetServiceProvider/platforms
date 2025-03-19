# 🚀 DHCP Server Setup with Kea using Vagrant

This project sets up a **DHCP server** using **Kea DHCP** on Ubuntu 22.04, deployed in a virtualized environment with **Vagrant** and **VirtualBox**.

---

## 📌 Requirements
- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/)
- Git (to clone the repository)

---

## 📖 Installation & Usage

### 1️⃣ Clone the Repository and Switch to the DHCP Branch
```bash
git clone https://github.com/yourusername/yourrepo.git
cd yourrepo
git checkout feature-dhcp-config

```

### 2️⃣ Start the Virtual Machine with the DHCP Server
```bash
vagrant up
```
This will download the Ubuntu 22.04 base image, install Kea DHCP, and apply the configuration.

### 3️⃣ Access the DHCP Server
```bash
vagrant ssh kea-dhcp
```
### 4️⃣ Check DHCP Service Status
```bash
sudo systemctl status kea-dhcp4-server
```
If active, you should see a message indicating that the service is running.

### 5️⃣ Verify DHCP Leases
```bash
cat /var/lib/kea/kea-leases4.csv
```
This will display the IP addresses assigned to clients.

📜 Key Files

- Vagrantfile: Defines the virtual machine and installs Kea DHCP.

- kea-dhcp4.conf: Configuration file for the DHCP server (automatically copied to the system).

⚡ Useful Commands

Shut down the VM:
```bash
vagrant halt
```
Destroy the VM:
```bash
vagrant destroy
```

Restart the configuration:
```bash
vagrant reload --provision
```
