#!/usr/bin/python
#upload binary for png files

import ftplib
import os
filename = "filename.png"
ftp = ftplib.FTP("SERVERADDRESS")
ftp.login("USERNAME", "PASSWORD")
ftp.cwd("/public_html/")
myfile = open(filename, 'r')
ftp.storbinary('STOR ' + filename, myfile)
myfile.close()

