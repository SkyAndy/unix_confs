#!/bin/bash

# BEGIN ALLE Stunde mal senden #
beacon -c DO7EN-15 -d WIDE1-1 -s "DB0LDS-2" ':DO7EN-15 :PARM.Asol,Vsol,Airpressure,Temperature,Humidity'
sleep 20
beacon -c DO7EN-15 -d WIDE1-1 -s "DB0LDS-2" ':DO7EN-15 :UNIT.A,V,Pa,degC,%'
sleep 20
beacon -c DO7EN-15 -d WIDE1-1 -s "DB0LDS-2" ':DO7EN-15 :EQNS.0,.01,0,0,.01,0,0,12.5,500,0,.1,-100,0,.1,0'
sleep 20
beacon -c DO7EN-15 -d WIDE1-1 -s "DB0LDS-2" ':DO7EN-15 :BITS.11111111,http://elenata.datenport.net/solarpower'
sleep 20
# ENDE ALLE Stunde mal senden #

# Das hier kannst DU senden wie Du möchtest
counter = `date "+%y%m%d%H%M%S"`
ladestrom = "185" #  1,85Ah
spannung = "1340" # 13,4V

# T#ZAHL die hochzählt darum habe ich das datum genommen
beacon -c DO7EN-15 -d WIDE1-1 -s "DB0LDS-2" 'T#'$counter','$ladestrom','$spannung',000,000,000,00000000'
sleep 20
beacon -c DO7EN-15 -d WIDE1-1 -s "DB0LDS-2" ';DO7EN-15 *111111z5236.60NE01311.90ESSolarPower'
