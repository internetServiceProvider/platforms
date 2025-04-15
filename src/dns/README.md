# Servidor DNS con BIND9 + DNSSEC + IPv6

Este proyecto despliega un servidor DNS seguro con BIND9 en Ubuntu 22.04 (Jammy), usando Vagrant y VirtualBox. Se configuran zonas directas e inversas (IPv4 e IPv6), y se habilita DNSSEC con generación y firma automática de claves.

## 🛠️ Requisitos

- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/)
- Sistema operativo anfitrión (Windows/Linux/Mac)

## 📁 Estructura del proyecto

```
dns/
├── config/
│   ├── zone_forward.json
│   ├── zone_reverse.json
│   └── zone_reverse_ipv6.json
├── scripts/
│   └── setup_dns.sh
└── Vagrantfile
```

## ⚙️ Configuración

### `Vagrantfile`

Define la VM `dns-server`:

- IP privada: `192.168.20.2`
- 512 MB de RAM y 1 vCPU
- Carpetas sincronizadas:
  - `./config` → `/vagrant/config`
  - `./scripts` → `/vagrant/scripts`
- Provisión automática con `setup_dns.sh`

### Archivos JSON

Los archivos `.json` definen la configuración DNS:

- `zone_forward.json`: Zona directa (A, AAAA, NS, CNAME, etc.)
- `zone_reverse.json`: Zona inversa IPv4
- `zone_reverse_ipv6.json`: Zona inversa IPv6

Ejemplo para `zone_forward.json`:
```json
{
  "origin": "midominio.test.",
  "records": [
    { "name": "ns1", "type": "A", "value": "192.168.20.2" },
    { "name": "ns1", "type": "AAAA", "value": "fd00::2" }
  ]
}
```

## 🧠 ¿Qué hace el script `setup_dns.sh`?

1. Instala BIND9 y herramientas.
2. Genera archivos de zona directos (A/AAAA) e inversos (PTR IPv4/IPv6).
3. Genera claves DNSSEC (KSK y ZSK).
4. Firma automáticamente la zona con `dnssec-signzone`.
5. Configura `named.conf.local` y `named.conf.options` con soporte IPv6 y DNSSEC.
6. Reinicia BIND9 para aplicar cambios.

## 🚀 Cómo desplegar

1. Clona el repositorio o copia los archivos.
2. Ubícate en el directorio `dns`.
3. Ejecuta:

```bash
vagrant up
```

4. Verifica el estado del servicio:

```bash
vagrant ssh
systemctl status named
```

## 🧪 Validación

Desde la VM puedes validar el funcionamiento:

```bash
dig @localhost midominio.test A
dig @localhost -x 192.168.20.2
dig @localhost -x fd00::2
```

Y para verificar DNSSEC:

```bash
dig +dnssec midominio.test
```

## ✅ Resultado

Servidor DNS funcional con:

- Resolución de nombres IPv4 e IPv6
- Zonas directas e inversas
- Soporte completo DNSSEC
- Configuración automatizada vía Vagrant

---

Autor: Samuel Barona  
Fecha: Abril 2025
