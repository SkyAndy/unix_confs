#!/bin/bash
# folgende Kommando erstellt eine RRD, die für die Aufnahme von Temperaturdaten
# alle 1min etwas rein mit max 2min Verspätung Min -20 Max 40 C° Rohdaten 

# RRA: Berechnung
# 1 Stunde = 3600 Sekunden, 24 Stunden * 3600 = 86400 Sekunden, 1 Minute = 60 Sekunden, wir wollen jede Minute einen Wert speichern, 86400 / 60 = 1440
# Die Anweisung RRA:AVERAGE:0.5:1:1440 reserviert also Platz für 1440 Einträge im zweitem Round Robin Archiv.
 
# Ist die Datenbank schon da? wenn nein anlegen
if [ ! -f cputemp.rrd ]; then
	rrdtool create cputemp.rrd --step 1 DS:temp:GAUGE:10:-20:50 \
	RRA:AVERAGE:0.5:1:86400 \
	RRA:AVERAGE:0.5:60:1440 \
	RRA:AVERAGE:0.5:60:10080 \
	RRA:AVERAGE:0.5:3600:720 \
	RRA:AVERAGE:0.5:86400:236 \
	RRA:MAX:0.5:1:86400 \
	RRA:MAX:0.5:60:1440 \
	RRA:MAX:0.5:60:10080 \
	RRA:MAX:0.5:3600:720 \
	RRA:MAX:0.5:86400:236

	echo "cputemp.rdd neu erstellt..."
fi

# ---8<--- ab hier cronjob --->8---

# Wert von der CPU auslesen
for ((i=1 ; i<=3600 ; i++ )); do 
	TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
	WERT=$(echo $(($TEMP/1000)))
	rrdtool update cputemp.rrd N:$WERT
	sleep 1
done

echo "Daten fertig"

rrdtool graph cpu1m.gif --start -60 --title "CPU-Temperatur" --vertical-label "Grad Celsius" DEF:cputemperatur=cputemp.rrd:temp:AVERAGE LINE1:cputemperatur#ff0000:"CPU-Temperatur 60 Datenpunkte"
rrdtool graph cpu1h.gif --start -1h --title "CPU-Temperatur" --vertical-label "Grad Celsius" DEF:cputemperatur=cputemp.rrd:temp:AVERAGE LINE1:cputemperatur#ff0000:"CPU-Temperatur 1h"
rrdtool graph cpu1d.gif --start -1d --title "CPU-Temperatur" --vertical-label "Grad Celsius" DEF:cputemperatur=cputemp.rrd:temp:AVERAGE LINE1:cputemperatur#ff0000:"CPU-Temperatur 1 Tag"
rrdtool graph cpu1w.gif --start end-30d --title "CPU-Temperatur" --vertical-label "Grad Celsius" DEF:cputemperatur=cputemp.rrd:temp:AVERAGE LINE1:cputemperatur#ff0000:"Temperatur letzten 30 Tage"

echo "Bilder fertig"

# DEF:cputemperatur=cputemp.rrd <-- DB Dateiname
# :temp<--Datenbank-Feldname
# :AVERAGE<--Durchschnitt

# LINE1<--haben ja nur einen Datenpunkt
# :cputemperatur<---Name der hinter "DEF:" stand
# #ff0000<--RGB Farbcode der Linie
# :"CPU-Temperatur 1m" <--- Titel

# letzten vier Wochen: --start end-4w --end 00:00
#       Januar 2001:  --start 20010101 --end start+31d
#       Januar 2001:  --start 20010101 --end 20010201
#       letzte hour:  --start end-1h
#       letzten 24h:  <nicht angeben Standart>
#           Gestern:  --end 00:00
