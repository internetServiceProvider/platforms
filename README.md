Configuración de Servidor DHCP con Kea usando Vagrant

Este proyecto configura un servidor DHCP utilizando Kea DHCP en Ubuntu 22.04, desplegado en un entorno virtualizado con Vagrant y VirtualBox.

📌 Requisitos

Vagrant

VirtualBox


🚀 Instalación y Uso

1️⃣ Clonar el Repositorio y Cambiar a la Rama DHCP

git clone https://github.com/tuusuario/tu-repo.git
cd tu-repo
git checkout feature-dhcp-config

2️⃣ Levantar la Máquina Virtual con el Servidor DHCP

vagrant up

Esto descargará la imagen base de Ubuntu 22.04, instalará Kea DHCP y aplicará la configuración.

3️⃣ Acceder al Servidor DHCP

vagrant ssh kea-dhcp

4️⃣ Verificar el Estado del Servicio DHCP

sudo systemctl status kea-dhcp4-server

Si está activo, verás un mensaje indicando que el servicio está en ejecución.

5️⃣ Verificar las Concesiones de DHCP

cat /var/lib/kea/kea-leases4.csv

Esto mostrará las direcciones IP asignadas a los clientes.

📜 Archivos Clave

Vagrantfile: Define la máquina virtual y la instalación de Kea.

kea-dhcp4.conf: Configuración del servidor DHCP (se copia automáticamente al sistema).

📌 Comandos Útiles

Apagar la máquina:

vagrant halt

Eliminar la máquina:

vagrant destroy

Reiniciar la configuración:

vagrant reload --provision

📜 Licencia

Este proyecto está bajo la licencia MIT.

Si tienes dudas o sugerencias, ¡abre un issue en el repositorio! 🚀

