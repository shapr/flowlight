# SPDX-FileCopyrightText: 2022 Dan Halbert for Adafruit Industries
#
# SPDX-License-Identifier: Unlicense

from secrets import secrets  # pylint: disable=no-name-in-module

from rainbowio import colorwheel
import binascii
import board
import microcontroller
import neopixel
import socketpool
import wifi
import math
import mdns

# from https://forums.adafruit.com/viewtopic.php?p=1016923&hilit=mdns#p1016923
mdns_server = mdns.Server(wifi.radio)
mdns_server.hostname = "flowlight"
print("MDNS Hostname: " + mdns_server.hostname)
mdns_server.advertise_service(service_type="_http", protocol="_tcp", port=80)

pixel_pin = board.A0 # what pin controls the neopixels?

num_pixels = 30 # how many neopixels do you have?

pixels = neopixel.NeoPixel(pixel_pin, num_pixels, brightness=0.3)
pixels.fill(0x01FF01)

from adafruit_httpserver import HTTPServer, HTTPResponse

ssid = secrets["ssid"]
print("Connecting to", ssid)
wifi.radio.connect(ssid, secrets["password"])
print("Connected to", ssid)
print(f"Listening on http://{wifi.radio.ipv4_address}:80")

pool = socketpool.SocketPool(wifi.radio)
server = HTTPServer(pool)

@server.route("/debug")
def debug(request):
    return HTTPResponse(status=200, body=f"{request.params}")

@server.route("/brightness")
def brightness(request):
    new_brightness = request.params['brightness']
    pixels.brightness = float(new_brightness)
    return HTTPResponse(status=200, body=f"{request.params}")

@server.route("/unsafe")
def unsafe(request):
    neopixel_values = request.params['runthis']
    neopixel_values = binascii.a2b_base64(neopixel_values).decode('utf-8')
    pixels[:] = eval(neopixel_values)
    return HTTPResponse(status=200, body=f"probly worked, good luck")

# @server.route("/activity")
# def unsafe(request):
#     neopixel_values = request.params['activity']
#     neopixel_values = binascii.a2b_base64(neopixel_values).decode('utf-8')

#     pixels[:] = eval(neopixel_values)
#     return HTTPResponse(status=200, body=f"probly worked, good luck")


# Never returns
server.serve_forever(str(wifi.radio.ipv4_address))
