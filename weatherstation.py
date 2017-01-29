#!/usr/bin/python

"""
This script expects 'rtl_433 2>&1' from stdin. It parses it's output and calculates the 10min average of the temperature and humidity
Simply execute this on your terminal >> rtl_433 2>&1 | python weatherstation.py
and open http://127.0.0.1:8001 on your browser
"""

import re
import fileinput
import time
import threading
import BaseHTTPServer
from email import utils
import os.path

class Weather(object):
	temp = []
	hum = []
	log = []

	logfilename = 'weather.log'

	def __init__(self):
		# Create logfile if not exist
		if not os.path.isfile(self.logfilename):
			with open(self.logfilename, 'w') as f:
				pass

		# Read log
		with open(self.logfilename) as f:
			for line in f:
				try:
					time, temp, hum = line.split(',')
					self.log.append([int(time), float(temp), float(hum)])
				except ValueError:
					pass # Line does not meet requirements to be valid

		# Open log for logging
		self.logfile = open('weather.log', 'a')

	"""Delete old entries which are older than 600 seconds"""
	def deleteOldEntries(self):
		# Delete old entries
		self.temp = [h for h in self.temp if h['time'] + 600 >= time.time()]
		self.hum  = [h for h in self.hum  if h['time'] + 600 >= time.time()]

	"""Calculate average temperature"""
	def getTemp(self):
		self.deleteOldEntries()
		cnttemp = len(self.temp)
		return sum(t['val'] for t in self.temp) / cnttemp if cnttemp != 0 else 0

	"""Calculate average humidity"""
	def getHum(self):
		self.deleteOldEntries()
		cnthum = len(self.hum)
		return sum(t['val'] for t in self.hum) / cnthum if cnthum != 0 else 0

	"""Returns all temperature and humidity entries"""
	def getEntries(self):
		self.deleteOldEntries()
		return [self.temp, self.hum]

	def appendTempVal(self, temp):
		print('DEBUG >> new temp val %.2f' % temp)
		self.temp.append({'time': time.time(), 'val': temp})

	def appendHumVal(self, hum):
		print('DEBUG >> new hum val %.0f' % hum)
		self.hum.append({'time': time.time(), 'val': hum})

	def makeLog(self):
		self.log.append([int(time.time()), self.getTemp(), self.getHum()])
		self.logfile.write("%d,%f,%f\r\n" % (int(time.time()), self.getTemp(), self.getHum()))

	def getLog(self):
		return self.log

class WeatherHandler(BaseHTTPServer.BaseHTTPRequestHandler):

	def do_HEAD(s):
		s.send_response(200)
		s.send_header("Content-type", "text/html")
		s.end_headers()

	def do_POST(s):
		s.send_response(200)
		s.send_header("Content-type", "text/html")
		s.end_headers()

	def do_GET(s):
		s.send_response(200)
		s.send_header("Content-type", "text/html")
		s.end_headers()

		if s.path == '/':

			# Current weather
			s.wfile.write('Temp: %.2f degC, Hum: %.0f %%, Entries: %d, %d<br>\r\n' % (weather.getTemp(), weather.getHum(), len(weather.getEntries()[0]), len(weather.getEntries()[1])))
			s.wfile.write('<a href="/log">Logging</a>\r\n')

		elif s.path == '/log':

			# Current log
			#for e in weather.getLog():
			#	s.wfile.write('Time: %d Temp: %.2f degC, Hum: %.0f %%<br>\r\n' % (e[0], e[1], e[2]))
			#s.wfile.write('<a href="/">back</a>\r\n')

			s.wfile.write("""<html>
			<head>
			<!--Load the AJAX API-->
			<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
			<script type="text/javascript">

			// Load the Visualization API and the corechart package.
			google.charts.load('current', {'packages':['line']});

			// Set a callback to run when the Google Visualization API is loaded.
			google.charts.setOnLoadCallback(drawChart);

			// Callback that creates and populates a data table,
			// instantiates the pie chart, passes in the data and
			// draws it.
			function drawChart() {

			var data = new google.visualization.DataTable();
			data.addColumn('date', 'Time');
			data.addColumn('number', 'Temperature');
			data.addColumn('number', 'Humidity');

			data.addRows([\r\n""")

			for e in weather.getLog():
				if e[1] != 0 and e[2] != 0:
					s.wfile.write('''[new Date('%s'), %.2f, %.0f],\r\n''' % (utils.formatdate(e[0]), e[1], e[2]))
			
			s.wfile.write("""]);

			var options = {
				chart: {
					title: 'Weather chart'
				},
				width: 1800,
				height: 500,
				series: {
					0: {axis: 'temp', format: 'decimal'},
					1: {axis: 'hum', format: 'percent'}
				},
				axes: {
					y: {
						temp: {label: 'Temperature (Celcius)'},
						hum: {label: 'Humidity (%)'}
					}
				}

			};

			var chart = new google.charts.Line(document.getElementById('chart_div'));

			chart.draw(data, options);
			}
			</script>
			</head>

			<body>
			<div id="chart_div"></div>
			<a href="/">back</a>
			</body>
			</html>""")





# This thread filters and parses the receiptions from rtl_433 2>&1
def listener(weather):
	for line in fileinput.input():

		m = re.search('error', line) # Captures errors
		if m is not None:
			print('DEBUG >> %s' % m.group(0))

		m = re.search('([a-zA-Z]*):.*?[-+]?([0-9]*\.[0-9]+|[0-9]+) ([A-Z%])', line) # Captures key and value (e.g. 'Temperature' and '10.5')
		if m is not None:

			key = m.group(1)
			val = float(m.group(2))
			unit = m.group(3)

			if key == 'Temperature' and val < 50 and val > -50: # Temperature filtering
				weather.appendTempVal(val)

			if key == 'Humidity' and val <= 100 and val >= 0: # Humidity filtering
				weather.appendHumVal(val)

# This thread logs the weather every 10 seconds
def logger(weather):
	while True:
		if int(time.time()) % 10 == 0:
			weather.makeLog()
			time.sleep(8)
		time.sleep(0.5)


print('DEBUG >> Initializing weather instance')
weather = Weather()

print('DEBUG >> Starting RF listener')
t = threading.Thread(target=listener, args=(weather, ))
t.start()

print('DEBUG >> Starting logger')
t = threading.Thread(target=logger, args=(weather, ))
t.start()

print('DEBUG >> Starting HTTP server')
server_class = BaseHTTPServer.HTTPServer
httpd = server_class(("", 8001), WeatherHandler)
try:
    httpd.serve_forever()
except KeyboardInterrupt:
    pass
httpd.server_close()
