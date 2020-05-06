# ssd1309-spin
--------------

This is a P8X32A/Propeller 1, P2X8C4M64P/Propeller 2 driver object for Solomon Systech SSD1309 OLED display controllers.
_NOTE_: In the future, this driver may be merged with the SSD1306 driver.

## Salient Features

* SPI connection at up to approx 4MHz (P1), ~10MHz (P2)
* Supports 128x32 and 128x64 displays
* Display mirroring (horizontal and vertical)
* Inverted display
* Variable contrast
* Low-level display control: Logic voltages, oscillator frequency, addressing mode, row/column mapping
* Supports display modules with or without discrete RESET pin
* Integration with the generic bitmap graphics library

## Requirements

* P1/SPIN1: 1 extra core/cog for the PASM I2C driver
* P2/SPIN2: N/A
* Presence of lib.gfx.bitmap library

## Compiler compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 4.1.4)

## Limitations

* Very early in development - may malfunction or outright fail to build
* Doesn't support parallel interface-connected displays (currently unplanned)
* Doesn't support I2C-connected displays (planned)
* Doesn't support hardware-accelerated scrolling features

## TODO

- [ ] Support hw-accelerated scrolling
- [ ] Support I2C-connected displays
