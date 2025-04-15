
# 📡 DHCPv4 Service – Kea on Ubuntu VM

This document explains how to deploy the `kea-dhcp4` service using Vagrant + VirtualBox on Ubuntu Server.

---

## 📁 Folder Structure

```
src/
└── dhcp/
│   └── Vagrantfile
│   └── kea-dhcp-config.json
```

---

## ⚙️ How It Works

- Installs `kea-dhcp4-server` and `mariadb-server`
- Copies your custom Kea configuration (`kea-dhcp-config.json`)
- Restarts the DHCP service using systemd

---

## 🚀 How to Deploy

```bash
# Go to the DHCP feature directory
cd features/dhcpv4

# Start the VM
vagrant up

# Stop the VM when done
vagrant halt

# If needed, destroy the VM
vagrant destroy
```

---

## 🔍 Network Configuration

The VM uses **two bridged adapters**:

1. **Wi-Fi (wlan0)** – dynamic IP via DHCP
2. **Ethernet (eth1)** – static IP: `192.168.20.3`

Both run in **promiscuous mode**, allowing the VM to serve DHCP properly on bridged networks.

---

## 🧩 Vagrantfile Summary

```ruby
config.vm.define "kea-dhcp4" do |dhcp4|
  dhcp4.vm.box = "ubuntu/jammy64"
  dhcp4.vm.hostname = "dhcp4"
  dhcp4.vm.network "public_network", type: "dhcp"
  dhcp4.vm.network "public_network", bridge: "eth1", ip: "192.168.20.3"

  dhcp4.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", "512", "--cpus", "1"]
    vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
    vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
  end

  # Install Kea and MariaDB
  dhcp4.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install -y mariadb-server kea-dhcp4-server kea-admin
  SHELL

  # Copy and activate config
  dhcp4.vm.provision "file", source: "kea-dhcp-config.json", destination: "/tmp/kea-dhcp4.json"
  dhcp4.vm.provision "shell", inline: <<-SHELL
    sudo mv /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.bak
    sudo mv /tmp/kea-dhcp4.json /etc/kea/kea-dhcp4.conf
    sudo systemctl restart kea-dhcp4-server
  SHELL
end
```

---

## 📌 Notes

- Make sure your host machine has `eth1` or change the bridge name accordingly.
- Validate `kea-dhcp4-server` status:
  
```bash
sudo systemctl status kea-dhcp4-server
```

- Log file (useful for troubleshooting):

```bash
sudo tail -f /var/log/syslog
```
