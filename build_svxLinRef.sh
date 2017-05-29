#!/bin/bash
# by DO07EN o5/2o17
# building svxlink / svxreflector from scratch
killall -9 svxlink

rm /usr/bin/svxlink
rm /usr/bin/remotetrx
rm /usr/bin/svxreflector
rm /usr/bin/siglevdetcal
rm /usr/sbin/svxlink_gpio_up
rm /usr/sbin/svxlink_gpio_down
rm -rf /usr/lib/arm-linux-gnueabihf/libasync*
rm -rf /usr/lib/arm-linux-gnueabihf/libecholib*
rm -rf /usr/lib/arm-linux-gnueabihf/svxlink

rm -rf /home/svxlink/svxlink
cd /home/svxlink
git clone https://github.com/sm0svx/svxlink.git

cd /home/svxlink/svxlink/src
mkdir build

cd build
cmake -DUSE_QT=OFF -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR=/etc -DLOCAL_STATE_DIR=/var -DCMAKE_BUILD_TYPE=Release ..
make
sudo make install

cd /home/svxlink/svxlink
git checkout svxreflector
git pull

cd /home/svxlink/svxlink/src/build
make
sudo make install

#Starte SVXLINK BASH
#/!bin/bash
#killall -9 svxlink
#sleep 3
#/usr/bin/svxlink --daemon --config /etc/svxlink/svxlink-r.conf --logfile /home/svxlink/svxlink.log
#sleep 10
#chmod uoa+rwx /tmp/svx*
#chown www-data:www-data /tmp/svx*
#exit 0
