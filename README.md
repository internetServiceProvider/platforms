<img src=https://www.icesi.edu.co/bioseguridad/images/2025/03/19/logo-blanco.png width="250" height="100" align="center">

-------------------
# ISP Platforms Deployment

Este repositorio contiene la infraestructura base para la implementación de servicios de red esenciales en un entorno de laboratorio para un Proveedor de Servicios de Internet (ISP). Está diseñado para ejecutarse en máquinas virtuales usando Vagrant y VirtualBox.

## 🧩 Servicios Implementados

- **DNS primario y secundario** con soporte para:
  - Registros A, AAAA, MX, TXT
  - PTR reverso
  - DNSSEC (RRSIG, DNSKEY)
  - TSIG
- **Servidor DHCPv4 con radvd para ipv6**
- **Servidor NTP**
- Scripts de validación de configuración DNS

# Diagramas y Diapositivas 
[Diagrama draw.io](https://drive.google.com/file/d/1fOLiqbf9Dqsi6Pjz7pXQDc1abWRWNbg0/view?usp=drive_link)

[Figma presentacion](https://www.figma.com/design/i5gnODzQy96CFGwsyb3TJU/Untitled?node-id=0-1&t=LBvQMpHkIHE7qB8F-1)

## 🗂️ Estructura del repositorio

```
platforms/
  └── src
        ├── dns/
        │   ├── config/
        │   │   ├── zone_forward.json
        │   │   ├── zone_reverse_ipv6.json
        │   │   ├── zone_reverse.json
        │   ├── scripts/
        │   │   ├── common_functions.sh
        │   │   ├── ntp_client_setup.sh
        │   │   ├── primary_setup.sh
        │   │   ├── secondary_setup.sh
        │   │   ├── test_dns.sh
        │   │   ├── test2_dns.sh
        │   │   └── test3_dns.sh
        │   └── vagrantfile
        ├── dhcp/
        │   ├── scripts/
        │   ├──  └── ntp_client_setup.sh
        │   ├── kea-dhcp-config.json
        │   └── vagrantfile
        ├── ntp/
        |   ├── ntp_server_setup.sh
        |   └── Vagrantfile
        └──
```

## ⚙️ Requisitos

- Vagrant >= 2.3.x
- VirtualBox >= 6.x
- Conexión NAT o Bridge a Internet

## 🚀 Despliegue

```bash
git clone https://github.com/internetServiceProvider/platforms.git
cd platforms/src
cd servicio/
vagrant up
vagrant ssh

```

Esto levantará las máquinas virtuales necesarias con los servicios configurados automáticamente.

## 🛠 DHCPv4 con Kea

La carpeta `dhcp/kea-dhcp-config.json` contiene la configuración base del servicio DHCPv4.

- Pool configurado: `192.168.90.10 – 192.168.90.60`
- Subred: `192.168.90.0/24`
- Gateway (routers): `192.168.90.1`
- DNS: `192.168.88.17` y `192.168.88.18`
- Dominio: `akranes.xyz`
- Timers personalizados:
  - valid-lifetime: 4000 s
  - renew-timer: 1000 s
  - rebind-timer: 2000 s

**Recomendaciones:**

- Verificar que la interfaz `enp0s9` esté activa y en la red correcta.
- Reiniciar el servicio tras cambios:
  ```bash
  sudo systemctl restart kea-dhcp4
  ```
- Monitorear logs:
  ```bash
  journalctl -u kea-dhcp4 -f
  ```

---

## 🌐 radvd (Router Advertisements para IPv6)

El servicio `radvd` envía anuncios Router Advertisement (RA) para permitir autoconfiguración IPv6 sin necesidad de DHCPv6.

### Configuración ejemplo:

```bash
interface enp0s9 {
  AdvSendAdvert on;
  prefix 2001:db8:a:b::/64 {
    AdvOnLink on;
    AdvAutonomous on;
    AdvRouterAddr on;
  };
};
```
### Comandos útiles:

```bash
sudo systemctl restart radvd
radvdump
ip -6 addr show enp0s9
```
## 📶 Pruebas de rendimiento con iperf3

`iperf3` es la herramienta utilizada para medir el rendimiento de la red local entre las máquinas virtuales.

### Instalación:

```bash
sudo apt update
sudo apt install iperf3
```

### Uso:

- En el servidor:
  ```bash
  iperf3 -s
  ```
- En el cliente:
  ```bash
  iperf3 -c <IP del servidor>
  ```

### Ejemplo:

```bash
iperf3 -c 192.168.88.32
```

---
---

## 🧪 Script de pruebas DNS

El archivo `src/dns/scripts/test3_dns.sh` valida lo siguiente:

- Resolución de registros A y PTR
- Respuesta de servidores primario, secundario y localhost
- Presencia de RRSIG y DNSKEY (DNSSEC)
- Transferencias AXFR bloqueadas
- Respuestas autoritativas (AA)
- Consistencia entre registros
- Respuesta correcta a NXDOMAIN

## 🔐 Seguridad DNS

- DNSSEC activado para el dominio `akranes.xyz`
- Claves DNSKEY disponibles y firmadas
- AXFR bloqueado por defecto
- Validación con `dig` +dnssec y grep RRSIG

## 👨‍💻 Autores

- Samuel Barona – Estudiante de Ingeniería Telemática
- Lina Andrade – Estudiante de Ingeniería Telemática
- Juan Velosa – Estudiante de Ingeniería Telemática
- Kevin Nieto – Estudiante de Ingeniería Telemática && sistemas
- Ricardo Urbina - Estudiante de Ingeniería Telemática && sistemas
  

## 📝 Licencia

MIT License – libre de usar, modificar y distribuir.
