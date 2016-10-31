#!/bin/bash

# BEGIN ALLE Seunde mal senden #
beacon -c DO7EN-15 -d WIDE1-1 -s "DB0LDS-2" ':DO7EN-15 :PARM.Asol,Vsol,Airpressure,Temperature,Humidity'
sleep 10
beacon -c DO7EN-15 -d WIDE1-1 -s "DB0LDS-2" ':DO7EN-15 :UNIT.A,V,Pa,degC,%'
sleep 10
beacon -c DO7EN-15 -d WIDE1-1 -s "DB0LDS-2" ':DO7EN-15 :EQNS.0,.01,0,0,.01,0,0,12.5,500,0,.1,0,0,.1,0'
sleep 10
beacon -c DO7EN-15 -d WIDE1-1 -s "DB0LDS-2" ':DO7EN-15 :BITS.11111111,http://elenata.datenport.net/solarpower'
sleep 10
# ENDE ALLE Stunde mal senden #

# Das hier kannst DU senden wie Du möchtest
counter=`date "+%y%m%d%H%M%S"`
ladestrom="185" #  1,85Ah
spannung="1340" # 13,4V
temperature=`vcgencmd measure_temp | cut -d "=" -f2 | cut -d"'" -f1 | awk  '{gsub(/\./,"",$0);printf $0}'`

# T#ZAHL die hochzählt darum habe ich das datum genommen
beacon -c DO7EN-15 -d WIDE1-1 -s "DB0LDS-2" 'T#'$counter','$ladestrom','$spannung',000,'$temperature',000,00000000'
sleep 10
beacon -c DO7EN-15 -d WIDE1-1 -s "DB0LDS-2" ';DO7EN-15 *111111z5236.60NE01311.90ESolarPower'

exit 0
