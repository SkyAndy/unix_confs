#!/usr/bin/php5
<?php
    $aprs_callsign = 'DO0SE';
    $aprs_passcode = 00000;
    // W is the WX icon. See http://wa8lmf.net/aprs/APRS_symbols.htm
    // Use GPS coordinate format, see http://www.csgnetwork.com/gpscoordconv.html
    $aprs_coord = '5236.64N/01311.94E';
    $aprs_icon ='r';
    $aprs_alt ='/A=000114';
    $aprs_comment = '439.975 -9.4Mhz DMR CC1 TG2621';
    $socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
    if ($socket) {
        $result = socket_connect($socket, 'hun.aprs2.net', 14580);
        if ($result) {
            // Authenticating
            $tosend = "user $aprs_callsign pass $aprs_passcode\n";
            socket_write($socket, $tosend, strlen($tosend));
            $authstartat = time();
            $authenticated = false;
            while ($msgin = socket_read($socket, 1000, PHP_NORMAL_READ)) {
                if (strpos($msgin, "$aprs_callsign verified") !== FALSE) {
                    $authenticated = true;
                    break;
                }
                // Timeout handling
                if (time()-$authstartat > 5)
                    break;
            }
            if ($authenticated) {
                // Sending position
                $tosend = "$aprs_callsign>APRS,TCPIP*:@" . date('Hmi') .
                "z$aprs_coord" .
                "$aprs_icon" .
                "$aprs_alt" .
                "$aprs_comment\n";
                socket_write($socket, $tosend, strlen($tosend));
                echo $tosend;
            }
        }
        socket_close($socket);
    }
?>
