# ISP Platforms Deployment

Este repositorio contiene la infraestructura base para la implementación de servicios de red esenciales en un entorno de laboratorio para un Proveedor de Servicios de Internet (ISP). Está diseñado para ejecutarse en máquinas virtuales usando Vagrant y VirtualBox.

## 🧩 Servicios Implementados

- **DNS primario y secundario** con soporte para:
  - Registros A, AAAA, MX, TXT
  - PTR reverso
  - DNSSEC (RRSIG, DNSKEY)
  - TSIG
- **Servidor DHCPv4**
- **Servidor NTP**
- Scripts de validación de configuración DNS

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
cd platforms
vagrant up
```

Esto levantará las máquinas virtuales necesarias con los servicios configurados automáticamente.

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
