#   vm creada para fines de testeo

Se creó esta vm a fines de testear cada servicio configurado

    - DNS (Primario y secundario)
    - DHCPv4 - radvd (Router Advertisement Daemon)
    - NTP
    - Iperf3


## 🗂️ Estructura del repositorio

```
platforms/
|  └── src
|    └── cientTest/
|       ├── ntpClient/
|       |   ├── ntp_client_setup.sh
|       ├── dnsTest/
|       |   ├── test_dns.sh
|       |   ├── test2_dns.sh
|       |   └── test3_dns.sh
|       └── vagrantfile
|
...
└── README.md
```

## Instrucciones del uso de los test dns 
Cada script de bash fue creado para comprobar los registros del dns 

```bash
# iniciamos la vm de DNS
vagrant up 
# Una vez inicializada las vms entramos por ssh al primary y secondary 
    #En este caso trabajaremos en el primary
vagrant ssh dns-primary
# vamos a esta ruta 
cd /vagrant/dnsTest
# configuramos las ip de los servidores dns

sudo vim test3_dns.sh

# --- Configuración ---
# Cambiar la ip por la ip de cada servidor (ip de documentacion)

PRIMARY_IP="192.0.2.1" #<--Cambiar esta ip--->
SECONDARY_IP="192.0.2.2" #<--Cambiar esta ip--->
LOCAL_IP="127.0.0.1"
DOMAIN="akranes.xyz"
RECORD="www"
PTR_IP="192.0.2.5" #<--Cambiar esta ip--->
NON_EXISTENT="noexiste"
EXPECTED_WWW="192.0.2.3" #<--Cambiar esta ip--->
EXPECTED_MAIL="192.0.2.4" #<--Cambiar esta ip--->

:wq
# Finalmente ejecutamos este script
sudo ./test3_dns.sh

```
## Test de ntp
para probar que el servicio de ntp esta funcionando tenemos que ejecutar el siguiente archivo 
```bash
cd /vagrant/ntpClient
sudo ./ntp_client_setup.sh
```
y automaticamente se configurará y sincronizará la vm con el servicio ntp

## Nota: el script te arrojará un error de que no se puede configurar el ntp, pero al realizar el comando "ntpq -p" podremos verificar que si se sincronizó correctamente 

## Test IPERF3

para iniciar esa prueba es necesario seleccionar un cliente y un servidor, en este caso esta vm estará trabajando como cliente, entonces desde esta vm ejecutamos el siguiente comando
```bash
iperf3 -c <IP-del-servidor>
```
Por otro lado, de parte del servidor escribimos este comando 

```bash
iperf3 -s
```
la interfaz de cada uno se verá algo tal que 
```
ciente> iperf - c <192.0.2.1> (<--ip de documentacion->)
-----------------------------------------
Cliente que se conecta al server (192.0.2.1), puerto TCP 5001
Tamaño de la ventana TCP: 59.9 KByte (predeterminado)
-------------------------------------------
[3] local <IP Addr node1> puerto 2357 conectado con <IP Addr node2> puerto 5001
[ID] Ancho de banda de transferencia de intervalo
[3] 0.0-10.0 seg 6.5 MBytes 5.2 Mbits/seg
```
```
server> iperf - s
--------------------------------------------------
Servidor escuchando en el puerto TCP 5001
Tamaño de la ventana TCP: 60.0 KByte (predeterminado)
----------------------------------------
[4] local <IP Addr node2> puerto 5001 conectado con <IP Addr node1> puerto 2357
[ID] Ancho de banda de transferencia de intervalo
[4] 0,0-10,1 seg 6,5 MBytes  

```