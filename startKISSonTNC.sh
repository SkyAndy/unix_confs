#!/bin/bash
# KISS einschalten RaspiB+ und TNC2H
# /etc/ax25/axports
# kiss0   DO7EN-1 19200   256     2       438.300 MHz (9600  bps)

killall -9 kissattach
sleep 1
# Firmware-TNCs in den KISS-Modus schalten
stty 19200 < /dev/ttyUSB0
echo -e "\r\033@K\r" > /dev/ttyUSB0
sleep 3
#
# KISS-Modul einbinden
modprobe ax25; modprobe mkiss
/usr/sbin/kissattach /dev/ttyUSB0 kiss0 192.168.1.1
# Parameter einstellen: P=128, W=10, TX-Delay=60
/usr/sbin/kissparms -p kiss0 -r 128 -s 10 -l 20 -t 60
echo 1000 > /proc/sys/net/ax25/ax0/t1_timeout
echo 300 > /proc/sys/net/ax25/ax0/t2_timeout
echo 30000 > /proc/sys/net/ax25/ax0/t3_timeout
echo 10 > /proc/sys/net/ax25/ax0/maximum_retry_count
echo 4 > /proc/sys/net/ax25/ax0/standard_window_size
echo 256 > /proc/sys/net/ax25/ax0/maximum_packet_length
sleep 1
beacon -c DO7EN -d WIDE2-1 -s "DO7EN-1" 'TNC2H-DK9SJ'
sleep 1
beacon -c DO7EN -d WIDE2-1 -s "DO7EN-1" 'KISS Modus aktiv'
