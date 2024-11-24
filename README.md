# flowlight
emacs+circuitpython implementation of a flow indicator

I read this paper: https://christop.club/publications/pdfs/Zuger-etal_2017.pdf

Summarized: You can detect if a programmer is in flow if they're typing into their programmer's editor.

# hardware
Required: Any CircuitPython board that can run an HTTP Server.
That means any board listed in "Available on these boards" on https://docs.circuitpython.org/en/latest/shared-bindings/socketpool/index.html
I'm using an AdaFruit FunHouse ( https://www.adafruit.com/product/4985 ) with a strip of 30 neopixels ( https://www.adafruit.com/product/4801 ).
If you use a strip with a different number of NeoPixels, you'll want to change the value for `num_pixels` in this line in code.py:
> num_pixels = 30 # how many neopixels do you have?

Make sure it matches the number of pixels on your strip!

# software
emacs!

# install
- copy code.py onto your HTTP server capable CircuitPython board.
- pitch flowlight.el into your emacs load-path
- in emacs, run these two functions:
  - (fl-write-interval-timer-start)
  - (fl-update-color-timer-start)
