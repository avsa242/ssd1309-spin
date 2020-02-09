{
    --------------------------------------------
    Filename: display.oled.ssd1306.i2c.spin2
    Description: Driver for Solomon Systech SSD1306, SSD1309 SPI OLED display drivers (P2 version)
    Author: Jesse Burt
    Copyright (c) 2018
    Created: Apr 26, 2018
    Updated: Dec 27, 2019
    See end of file for terms of use.
    --------------------------------------------
}
#define SSD130X
#include "lib.gfx.bitmap.spin"

CON

OBJ

    core    : "core.con.ssd1309"
    time    : "time"
    io      : "io"
    spi     : "com.spi.4w"

VAR

    long _draw_buffer
    word _buff_sz
    byte _disp_width, _disp_height, _disp_xmax, _disp_ymax
    byte _CS, _SCK, _MOSI, _DC, _RES

PUB Null
' This is not a top-level object

PUB Start(width, height, CS_PIN, SCK_PIN, SDA_PIN, DC_PIN, RES_PIN, dispbuffer_address): okay
' Start the driver with custom settings
' Valid values:
'       width: 0..128
'       height: 32, 64
'       CS_PIN, SCK_PIN, SDA_PIN, DC_PIN, RES_PIN: 0..31
    if lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and lookdown(DC_PIN: 0..31)
'        if okay := spi.Start(SDA_PIN, SCK_PIN, spi#MSBPRE, spi#MSBFIRST, core#SCK_DELAY, core#SCK_CPOL)
        if okay := spi.Start(core#SCK_DELAY, core#SCK_CPOL)
            _CS := CS_PIN
            _SCK := SCK_PIN
            _MOSI := SDA_PIN
            _DC := DC_PIN
            _RES := RES_PIN

            io.Low (_DC)
            io.High (_CS)
            io.High (_RES)
            io.Output (_DC)
            io.Output (_CS)
            io.Output (_RES)

            Reset

            _disp_width := width
            _disp_height := height
            _disp_xmax := _disp_width-1
            _disp_ymax := _disp_height-1
            _buff_sz := (_disp_width * _disp_height) / 8
            Address(dispbuffer_address)
            return
    return FALSE                                                'If we got here, something went wrong

PUB Stop

    DisplayOff

PUB Defaults

    DisplayOff
    OSCFreq (444)
    MuxRatio(_disp_height-1)
    DisplayOffset(0)
    DisplayStartLine(0)
    ChargePumpReg(TRUE)
    AddrMode (0)
    MirrorH(FALSE)
    MirrorV(FALSE)
    case _disp_height
        32:
            COMPinCfg(0, 0)
        64:
            COMPinCfg(1, 0)
        OTHER:
            COMPinCfg(0, 0)
    Contrast(127)
    PrechargePeriod (1, 15)
    VCOMHDeselectLevel ($40)
    EntireDisplayOn(FALSE)
    InvertDisplay(FALSE)
    ColumnStartEnd (0, _disp_width-1)
    case _disp_height
        32:
            PageRange (0, 3)
        64:
            PageRange (0, 7)
        OTHER:
            PageRange (0, 3)
    DisplayOn

PUB Address(addr)
' Set framebuffer address
    case addr
        $0004..$7FFF-_buff_sz:
            _draw_buffer := addr
            result := _draw_buffer
            return
        OTHER:
            result := _draw_buffer
            return

PUB AddrMode(mode)
' Set Memory Addressing Mode
'   0: Horizontal addressing mode
'   1: Vertical
'   2: Page (POR)
    case mode
        0, 1, 2:
        OTHER:
            return

    writeReg(core#CMD_MEM_ADDRMODE, 1, mode)

PUB BufferSize
' Get size of buffer
    return _buff_sz

PUB ChargePumpReg(enabled)
' Enable Charge Pump Regulator when display power enabled
    case ||enabled
        0, 1:
            enabled := lookupz(||enabled: $10, $14)
        OTHER:
            return
    writeReg(core#CMD_CHARGEPUMP, 1, enabled)

PUB ClearAccel
' Dummy method

PUB ColumnStartEnd(column_start, column_end)
' Set display start and end columns
    case column_start
        0..127:
        OTHER:
            column_start := 0

    case column_end
        0..127:
        OTHER:
            column_end := 127

    writeReg(core#CMD_SET_COLADDR, 2, (column_end << 8) | column_start)

PUB COMPinCfg(pin_config, remap) | config
' Set COM Pins Hardware Configuration and Left/Right Remap
'  pin_config: 0: Sequential                      1: Alternative (POR)
'       remap: 0: Disable Left/Right remap (POR)  1: Enable remap
' POR: $12
    config := %0000_0010
    case pin_config
        0:
        OTHER:
            config := config | (1 << 4)

    case remap
        1:
            config := config | (1 << 5)
        OTHER:

    writeReg(core#CMD_SETCOM_CFG, 1, config)

PUB Contrast(level)
' Set Contrast Level 0..255 (POR = 127)
    case level
        0..255:
        OTHER:
            level := 127

    writeReg(core#CMD_CONTRAST, 1, level)

PUB DisplayOn
' Power on display
    writeReg(core#CMD_DISP_ON, 0, 0)

PUB DisplayOff
' Power off display
    writeReg(core#CMD_DISP_OFF, 0, 0)

PUB DisplayOffset(offset)
' Set Display Offset/vertical shift from 0..63
' POR: 0
    case offset
        0..63:
        OTHER:
            offset := 0

    writeReg(core#CMD_SETDISPOFFS, 1, offset)

PUB DisplayStartLine(start_line)
' Set Display Start Line from 0..63
    case start_line
        0..63:
        OTHER:
            return

    writeReg($40, 0, start_line)

PUB DrawBitmap(addr_bitmap)
' Blits bitmap to display buffer
    bytemove(_draw_buffer, addr_bitmap, _buff_sz)

PUB EntireDisplayOn(enabled)
' TRUE    - Turns on all pixels (doesn't affect GDDRAM contents)
' FALSE   - Displays GDDRAM contents
    case ||enabled
        0, 1:
            enabled := ||enabled
        OTHER:
            return

    writeReg(core#CMD_RAMDISP_ON, 0, enabled)

PUB InvertDisplay(enabled)
' Invert display
    case ||enabled
        0, 1:
            enabled := ||enabled
        OTHER:
            return

    writeReg(core#CMD_DISP_NORM, 0, enabled)

PUB MirrorH(enabled)
' Mirror display, horizontally
' NOTE: Only affects subsequent data - no effect on data in GDDRAM  'XXX clarify
    case ||enabled
        0, 1: enabled := ||enabled
        OTHER:
            return

    writeReg(core#CMD_SEG_MAP0, 0, enabled)

PUB MirrorV(enabled)
' Mirror display, vertically
' NOTE: Only affects subsequent data - no effect on data in GDDRAM
' POR: 0
    case ||enabled
        0:
        1: enabled := 8
        OTHER:
            return

    writeReg(core#CMD_COMDIR_NORM, 0, enabled)

PUB MuxRatio(mux_ratio)
' Valid values: 16..64
    case mux_ratio
        16..64:
        OTHER:
            return

    writeReg(core#CMD_SETMUXRATIO, 1, mux_ratio-1)

PUB OSCFreq(kHz)
' Set Oscillator frequency, in kHz
'   Valid values: 360, 372, 384, 396, 408, 420, 432, 444, 456, 468, 480, 492, 504, 516, 528, 540
'   Any other value is ignored
'   NOTE: Range is interpolated, based solely on the range specified in the datasheet, divided into 16 steps
    case kHz
        core#FOSC_MIN..core#FOSC_MAX:
            kHz := lookdownz(kHz: 360, 372, 384, 396, 408, 420, 432, 444, 456, 468, 480, 492, 504, 516, 528, 540) << core#FLD_OSCFREQ
        OTHER:
            return

    writeReg(core#CMD_SETOSCFREQ, 1, kHz)

PUB PageRange(pgstart, pgend)

    case pgstart
        0..7:
        OTHER:
            pgstart := 0

    case pgend
        0..7:
        OTHER:
            pgend := 7

    writeReg(core#CMD_SET_PAGEADDR, 2, (pgend << 8) | pgstart)

PUB PrechargePeriod(phs1_clks, phs2_clks)
' Set Pre-charge period: 1..15 DCLK
' POR: 2 (both)
    case phs1_clks
        1..15:
        OTHER:
            phs1_clks := 2

    case phs2_clks
        1..15:
        OTHER:
            phs2_clks := 2

    writeReg(core#CMD_SETPRECHARGE, 1, (phs2_clks << 4) | phs1_clks)

PUB Reset
' Reset the display controller
    if lookup(_RES: 0..31)
        io.High(_RES)
        time.USleep(3)
        io.Low(_RES)
        time.USleep(3)
        io.High(_RES)

PUB VCOMHDeselectLevel(level)
' Set Vcomh deselect level 0.65, 0.77, 0.83 * Vcc
'   Valid values: 0.65, 0.77, 0.83
'   Any other value sets the POR value, 0.77
    case level
        0.67:
            level := %000 << 4
        0.77:
            level := %010 << 4
        0.83:
            level := %011 << 4
        OTHER:
            level := %010 << 4

    writeReg(core#CMD_SETVCOMDESEL, 1, level)

PUB Update | tmp
' Write display buffer to display
    ColumnStartEnd (0, _disp_width-1)
    PageRange (0, 7)

    io.Low(_CS)
    io.High(_DC)
    repeat tmp from 0 to _buff_sz-1
        spi.ShiftOut(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[_draw_buffer][tmp])
    io.High(_CS)

PUB WriteBuffer(buff_addr, buff_sz) | tmp
' Write buff_sz bytes of buff_addr to display
    ColumnStartEnd (0, _disp_width-1)
    PageRange (0, 7)

    io.Low(_CS)
    io.High(_DC)
    repeat tmp from 0 to buff_sz-1
        spi.ShiftOut(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buff_addr][tmp])
    io.High(_CS)

PRI writeReg(reg, nr_bytes, val) | cmd_packet[2], tmp, ackbit
' Write nr_bytes to register 'reg' stored in val
' If nr_bytes is
'   0, It's a command that has no arguments - write the command only
'   1, It's a command with a single byte argument - write the command, then the byte
'   2, It's a command with two arguments - write the command, then the two bytes (encoded as a word)
    case nr_bytes
        0:
            cmd_packet.byte[0] := reg | val 'Simple command
            nr_bytes := 1
        1:
            cmd_packet.byte[0] := reg       'Command w/1-byte argument
            cmd_packet.byte[1] := val
            nr_bytes := 2
        2:
            cmd_packet.byte[0] := reg       'Command w/2-byte argument
            cmd_packet.byte[1] := val & $FF
            cmd_packet.byte[2] := (val >> 8) & $FF
            nr_bytes := 3
        OTHER:
            return $DEADC0DE

    io.Low(_CS)
    io.Low(_DC)
    repeat tmp from 0 to nr_bytes-1
        spi.ShiftOut(_MOSI, _SCK, core#MOSI_BITORDER, 8, cmd_packet.byte[tmp])
    io.High(_CS)

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
