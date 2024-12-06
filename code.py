import mdns
import microcontroller
import neopixel
import socketpool
import terminalio
import wifi
from adafruit_magtag.magtag import MagTag
from adafruit_httpserver import Server, Request, Response, JSONResponse, GET

magtag = MagTag()
magtag.peripherals.neopixel_disable = False

# free at start up (set to green)
magtag.peripherals.neopixels.fill((0,0,255))

magtag.add_text(
    text_font=terminalio.FONT,
    text_position=(140, 55),
    text_scale=7,
    text_anchor_point=(0.5, 0.5),
)

# from https://forums.adafruit.com/viewtopic.php?p=1016923&hilit=mdns#p1016923
mdns_server = mdns.Server(wifi.radio)
mdns_server.hostname = "flowlight"
print("MDNS Hostname: " + mdns_server.hostname)
mdns_server.advertise_service(service_type="_http", protocol="_tcp", port=80)

pool = socketpool.SocketPool(wifi.radio)
server = Server(pool, debug=True)

@server.route("/cpu-information", append_slash=True)
def cpu_information_handler(request: Request):
    """
    Return the current CPU temperature, frequency, and voltage as JSON.
    """
    data = {
        "temperature": microcontroller.cpu.temperature,
        "frequency": microcontroller.cpu.frequency,
        "voltage": microcontroller.cpu.voltage,
    }
    return JSONResponse(request, data)

@server.route("/color", GET)
def change_neopixel_color_handler_query_params(request: Request):
    """Changes the color of the built-in NeoPixel using query/GET params."""
    # e.g. /change-neopixel-color?r=255&g=0&b=0
    r = request.query_params.get("r") or 0
    g = request.query_params.get("g") or 0
    b = request.query_params.get("b") or 0

    magtag.peripherals.neopixels.fill((int(r), int(g), int(b)))

    return Response(request, f"Changed NeoPixel to color ({r}, {g}, {b})")

@server.route("/status", GET)
def set_status(request: Request):
    """Changes the color of the built-in NeoPixels and the status text using query/GET params."""
    # e.g. /status?status=busy or /status?status=free
    status = request.query_params.get("status")
    response = ""
    if status == "busy":
        magtag.peripherals.neopixels.fill((255, 0, 0))
        magtag.set_text("BUSY")
        response = "busy"
    elif status == "free":
        magtag.peripherals.neopixels.fill((0, 255, 0))
        magtag.set_text("FREE")
        response = "free"
    else:
        magtag.peripherals.neopixels.fill((0, 0, 255))
        magtag.set_text("ERROR")
        response = "error"

    return Response(request, f"Changed status to {response}")

server.serve_forever(str(wifi.radio.ipv4_address),80)
