# Implementación de Firewall Virtualizado en Infraestructura de Red

## Resumen

Este documento presenta la implementación de un firewall virtualizado utilizando Access Control Lists (ACL) extendidas en un router Cisco ISR4321. La solución fue desarrollada para proteger la infraestructura de red ante las limitaciones encontradas con herramientas de firewall tradicionales como UFW y nftables en el entorno virtualizado específico del proyecto.

## 1. Introducción

### 1.1 Objetivo

Implementar un sistema de filtrado de paquetes que proporcione control granular del tráfico de red, asegurando que únicamente los servicios autorizados sean accesibles desde la red interna hacia los servidores de producción.

### 1.2 Alcance

La implementación cubre el filtrado de tráfico IPv4 e IPv6 en la interfaz GigabitEthernet0/0/1 del router principal, controlando el acceso a servicios críticos como SSH, HTTP y HTTPS.

## 2. Marco Teórico

### 2.1 Tecnologías de Firewall en Linux

### 2.1.1 Nftables

Nftables representa la evolución moderna de los frameworks de filtrado de paquetes en Linux, diseñado como sustituto unificado de iptables, ip6tables, arptables y ebtables. Sus características principales incluyen:

-   **Arquitectura modular**: Las reglas se organizan en cadenas dentro de tablas
-   **Sintaxis unificada**: Manejo consistente de IPv4 e IPv6
-   **Persistencia**: Configuración almacenada en `/etc/nftables.conf`

**Comandos básicos de administración:**

```bash
# Guardar configuración actual
nft list ruleset > /etc/nftables.conf

# Reiniciar servicio
systemctl restart nftables.service

# Crear tabla de filtrado
nft add table ip filtered

# Listar configuración
nft list tables

```

### 2.1.2 Familias de Protocolos

Nftables soporta múltiples familias de protocolos:

-   **ip**: IPv4
-   **ip6**: IPv6
-   **inet**: IPv4 e IPv6 combinados
-   **arp**: Address Resolution Protocol
-   **bridge**: Tráfico de puente
-   **netdev**: Filtrado a nivel de dispositivo de red

### 2.2 Tipos de Cadenas

-   **Cadenas base**: Puntos de entrada para paquetes desde la pila de red
-   **Cadenas normales**: Utilizadas como objetivos de salto para organización lógica

### 2.1.2. **UFW**

Las siglas "UFW" significan "Uncomplicated Firewall" y hacen referencia a una aplicación que tiene como objetivo establecer reglas en "iptables", las tablas de firewall nativas en Linux. Puesto que iptables tiene una sintaxis relativamente compleja, utilizar UFW para realizar su configuración es una alternativa útil sin escatimar en seguridad.

### 2.1.3. ACLs

Las ACLs extendidas (Access Control Lists extendidas) son un tipo de lista de control de acceso en redes de computadoras que permiten un filtrado más granular del tráfico en comparación con las ACLs estándar. Se utilizan comúnmente en routers y switches para controlar el flujo de datos basado en múltiples criterios.

## 3. Análisis de Limitaciones del Entorno

### 3.1 Restricciones Identificadas

### 3.1.1 Incompatibilidad con UFW

Durante la fase de implementación se identificó que Uncomplicated Firewall (UFW) presentaba incompatibilidades con el bridge de red utilizado en Faraday. Esta limitación impidió la configuración directa de reglas de firewall en los sistemas host.

### 3.1.2 Limitaciones de nftables

La implementación de nftables se vio comprometida por las siguientes restricciones técnicas:

-   **Enmascaramiento de direcciones IP**: Todo el tráfico de red aparecía originado desde la dirección IP 192.168.50.2 del bridge
-   **Pérdida de visibilidad**: Imposibilidad de identificar el origen real del tráfico de red
-   **Control limitado**: Falta de control granular sobre equipos individuales dentro de la red

### 3.2 Estrategia de Mitigación

Ante estas limitaciones, se optó por implementar el filtrado de tráfico a nivel de router utilizando Access Control Lists (ACL) extendidas, proporcionando un punto de control centralizado y efectivo.

## 4. Implementación de la Solución

### 4.1 Arquitectura de Red

La solución se implementó en la interfaz GigabitEthernet0/0/1 del router Cisco ISR4321 con la siguiente configuración:

```
interface GigabitEthernet0/0/1
 ip address 192.168.50.1 255.255.255.224
 ip nat inside
 ip access-group ACL_G0-0-1_IN in
 ipv6 address autoconfig
 ipv6 enable
 ipv6 traffic-filter ACL_G0-0-1_IN_v6 in

```

### 4.2 Configuración de ACL IPv4

### 4.2.1 Estructura de la ACL Principal

```
ip access-list extended ACL_G0-0-1_IN
 ! Control de acceso SSH restringido
 permit tcp host 192.168.88.100 any eq 22

 ! Control de diagnósticos de red
 permit icmp host 192.168.88.100 any

 ! Servicios web públicos
 permit tcp any any eq 80
 permit tcp any any eq 443

 ! API de Kubernetes
 permit tcp 192.168.50.0 0.0.0.31 192.168.18.0 0.0.0.255 eq 6443

 ! Protocolos de soporte
 permit udp any any
 permit tcp any any established

 ! Bloqueo de contenido no autorizado
 deny ip any host 3.33.243.145 log
 deny ip any host 15.197.204.56 log

 ! Políticas de denegación con logging
 deny tcp any any eq 22 log
 deny icmp any any log
 deny ip any any log

```

### 4.2.2 Análisis de Reglas Implementadas

**Reglas de Permitir:**

1. **SSH Restringido**: Acceso administrativo limitado al host 192.168.88.100
2. **ICMP Controlado**: Diagnósticos de red únicamente desde equipo de administración
3. **Servicios Web**: Acceso HTTP/HTTPS sin restricciones para funcionamiento normal
4. **API Kubernetes**: Comunicación entre subredes 192.168.50.0/27 y 192.168.18.0/24
5. **Tráfico UDP**: Servicios esenciales (DNS, DHCP, NTP)
6. **Conexiones Establecidas**: Tráfico de retorno para sesiones iniciadas internamente

**Reglas de Denegar:**

1. **Filtrado de Contenido**: Bloqueo de direcciones IP específicas asociadas a contenido no autorizado
2. **SSH No Autorizado**: Registro de intentos de acceso SSH desde fuentes no permitidas
3. **ICMP No Autorizado**: Prevención de reconocimiento de red desde fuentes externas
4. **Tráfico Residual**: Denegación por defecto con logging completo

## 5. Análisis de Tráfico Bloqueado

### 5.1 Tráfico Kubernetes Identificado

Durante el monitoreo se identificaron múltiples intentos de conexión al puerto 6443 (API de Kubernetes):

```
list ACL_G0-0-1_IN denied tcp 192.168.50.2(23153) -> 192.168.18.7(6443)

```

Este patrón indica comunicación legítima entre nodos del clúster que requirió la implementación de reglas específicas para el puerto 6443.

### 5.2 Estadísticas de Bloqueo

Los logs muestran un volumen significativo de tráfico filtrado, con más de 496 paquetes bloqueados en intervalos cortos, validando la efectividad del sistema de filtrado implementado.

## 6. Validación y Monitoreo

### 6.1 Comandos de Verificación

```
show access-lists
show ipv6 access-list
show ip interface GigabitEthernet0/0/1
show ipv6 interface GigabitEthernet0/0/1

```

### 6.2 Persistencia de Configuración

```
write memory
copy running-config startup-config

```

## 7. Conclusiones

### 7.1 Logros Alcanzados

-   Implementación exitosa de filtrado de tráfico centralizado
-   Control granular de acceso a servicios críticos
-   Visibilidad completa del tráfico bloqueado mediante logging
-   Soporte dual para IPv4 e IPv6
-   Integración transparente con la infraestructura Kubernetes existente

### 7.2 Beneficios de Seguridad

-   **Principio de menor privilegio**: Acceso SSH restringido a equipos autorizados
-   **Prevención de reconocimiento**: Bloqueo de ping desde fuentes no autorizadas
-   **Filtrado de contenido**: Capacidad de bloquear sitios web específicos
-   **Auditoría completa**: Registro detallado de intentos de acceso denegados

### 7.3 Ventajas de la Solución Implementada

La solución basada en ACL ofrece ventajas significativas sobre las alternativas evaluadas:

-   **Centralización**: Control único en el punto de entrada de red
-   **Transparencia**: Visibilidad completa del tráfico sin enmascaramiento
-   **Escalabilidad**: Capacidad de gestionar múltiples subredes desde un punto central
-   **Compatibilidad**: Integración nativa con infraestructura Cisco existente

## 8. Recomendaciones Futuras

### 8.1 Mejoras Propuestas

-   Implementación de reglas de filtrado por tiempo
-   Integración con sistemas de gestión de eventos de seguridad (SIEM)
-   Automatización de actualizaciones de listas de bloqueo
-   Implementación de rate limiting para prevenir ataques de denegación de servicio

### 8.2 Monitoreo Continuo

Se recomienda establecer un programa de revisión periódica de logs para identificar patrones de tráfico malicioso y ajustar las reglas de filtrado según sea necesario.

---

**Documento preparado por**: Juan Manuel Velosa y Esteban Gaviria Zambrano

**Fecha de última actualización**: 10 de Junio de 2025
