{
    --------------------------------------------
    Filename: SSD1309-OLED-Demo.spin
    Description: Demo of the ssd1309 spi driver (Configured for SSD1309)
    Author: Jesse Burt
    Copyright (c) 2018
    Created: Apr 26, 2018
    Updated: Mar 12, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1

    CS_PIN      = 0
    SCK_PIN     = 1
    SDA_PIN     = 2
    DC_PIN      = 3
    RES_PIN     = 4

    WIDTH       = 128
    HEIGHT      = 64

    BUFFSZ      = (WIDTH * HEIGHT) / 8
    XMAX        = WIDTH-1
    YMAX        = HEIGHT-1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    oled    : "display.oled.ssd1309.spi"
    int     : "string.integer"
    fnt5x8  : "font.5x8"
VAR

    byte _framebuff[BUFFSZ]
    byte _fps, _fps_mon_cog
    long _fps_mon_stack[50]
    long _rndSeed

    long bx, by, dx, dy

PUB Main | x, y, ch

    _fps := 0
    Setup
    oled.ClearAll
    oled.Contrast(127)

    oled.FGColor(1)
    oled.BGColor(0)
    Demo_Greet
    time.Sleep (5)
    oled.ClearAll
{
    Demo_Sine (100)
    oled.ClearAll

    Demo_Wave (100)
    oled.ClearAll

    Demo_MEMScroller($0000, $FFFF-BUFFSZ)
    oled.ClearAll

    Demo_DrawBitmap (@Beanie, 500)
    oled.ClearAll

    Demo_LineSweep(2)
    oled.ClearAll

    Demo_LineRND (100)
    oled.ClearAll

    Demo_PlotRND (100)
    oled.ClearAll

    Demo_BouncingBall (100, 5)
    oled.ClearAll

    Demo_ExpandingCircle(5)
    oled.ClearAll

    Demo_Wander (500)
    oled.ClearAll

    Demo_Text (100)
    oled.ClearAll
}
    Demo_Contrast(2, 1)
    oled.ClearAll

    Stop

PUB Demo_BouncingBall(frames, radius)
'' Draws a simple ball bouncing off screen edges
    bx := (rnd(XMAX) // (WIDTH - radius * 4)) + radius * 2  'Pick a random screen location to
    by := (rnd(YMAX) // (HEIGHT - radius * 4)) + radius * 2 ' start from
    dx := rnd(4) // 2 * 2 - 1                               'Pick a random direction to
    dy := rnd(4) // 2 * 2 - 1                               ' start moving

    repeat frames
        bx += dx
        by += dy
        if (by =< radius OR by => HEIGHT - radius)          'If we reach the top or bottom of the screen,
            dy *= -1                                        ' change direction
        if (bx =< radius OR bx => WIDTH - radius)           'Ditto with the left or right sides
            dx *= -1

        oled.Circle (bx, by, radius, 1)
        oled.Update
        _fps++
        oled.Clear

PUB Demo_DrawBitmap(addr_bitmap, reps)' XXX stock bitmap unsuitable for 64-height display
'' Continuously redraws bitmap at address 'addr_bitmap' (e.g., Demo_DrawBitmap(@bitmap1, 500)
'' Visually unexciting - just for demonstrating the max blit speed
    repeat reps
        oled.Bitmap (addr_bitmap, BUFFSZ, 0)
        oled.Update
        _fps++

PUB Demo_ExpandingCircle(reps) | i, x, y
'' Draws circles at random locations, expanding in radius
    repeat reps
        x := rnd(XMAX)
        y := rnd(YMAX)
        repeat i from 1 to 31
            oled.Circle (x, y, ||i, -1)
            oled.Update
            _fps++
            oled.Clear

PUB Demo_Contrast(reps, delay_ms) | contrast_level
'' Fades out and in display contrast
    repeat reps
        repeat contrast_level from 255 to 1
            oled.Contrast (contrast_level)
            time.MSleep (delay_ms)
        repeat contrast_level from 0 to 254
            oled.Contrast (contrast_level)
            time.MSleep (delay_ms)

PUB Demo_Greet
'                           |0   |5  1|0  1|5
    oled.Position (0, 0)
    oled.Str (string("SSD1309 on the"))

    oled.Position (0, 1)
    oled.Str (string("Parallax"))

    oled.Position (0, 2)
    oled.Str (string("P8X32A @ "))
    oled.Str (int.Dec(clkfreq/1_000_000))
    oled.Str (string("MHz"))

    oled.Position (0, 3)
    oled.Str (int.DecPadded (WIDTH, 3))

    oled.Position (3, 3)
    oled.Str (string("x"))

    oled.Position (4, 3)
    oled.Str (int.DecPadded (HEIGHT, 2))
    oled.Update

PUB Demo_LineRND (reps)' | x, y
'' Draws random lines with color -1 (invert)
    repeat reps
        oled.Line (rnd(XMAX), rnd(YMAX), rnd(XMAX), rnd(YMAX), -1)
        oled.Update
        _fps++

PUB Demo_LineSweep (reps) | x, y
'' Draws lines top left to lower-right, sweeping across the screen, then
''  from the top-down
    repeat reps
        repeat x from 0 to XMAX step 1
            oled.Line (x, 0, XMAX-x, YMAX, -1)
            oled.Update
            _fps++

        repeat y from 0 to YMAX step 1
            oled.Line (XMAX, y, 0, YMAX-y, -1)
            oled.Update
            _fps++

PUB Demo_MEMScroller(start_addr, end_addr) | pos, st, en
'' Dumps Propeller Hub RAM (and/or ROM) to the framebuffer
    repeat pos from start_addr to end_addr step 128
        oled.Bitmap (pos, BUFFSZ, 0)
        oled.Update
'        time.MSleep (30)                                   ' Uncomment this line to slow this demo down a bit
        _fps++

PUB Demo_PlotRND (reps) | x, y
'' Draws random pixels to the screen, with color -1 (invert)
    repeat reps
        oled.Plot (rnd(XMAX), rnd(YMAX), -1)
        oled.Update
        _fps++

PUB Demo_Sine(reps) | x, y, modifier, offset, div
'' Draws a sine wave the length of the screen, influenced by
''  the system counter
    case HEIGHT
        32:
            div := 4096
        64:
            div := 2048
        OTHER:
            div := 2048

    offset := YMAX/2                                    ' Offset for Y axis

    repeat reps
        repeat x from 0 to XMAX
            modifier := (||cnt / 1_000_000)           ' Use system counter as modifier
            y := offset + sin(x * modifier) / div
            oled.Plot(x, y, 1)
        oled.Update
        _fps++
        oled.Clear

PUB Demo_Text(reps) | col, row, maxcol, maxrow, ch, st
'' Sequentially draws the whole font table to the screen, for half of 'reps'
''  then random characters for the second half
    maxcol := (WIDTH/oled.FontWidth)-1   'XXX In the future, pull part of this from a font def file,
    maxrow := (HEIGHT/oled.FontHeight)-1  ' based on its size
    ch := $00
    repeat reps/2
        repeat row from 0 to maxrow
            repeat col from 0 to maxcol
                ch++
                if ch > $7F
                    ch := $00
                oled.Position (col, row)
                oled.Char (ch)
        oled.Update
        _fps++

    repeat reps/2
        repeat row from 0 to maxrow
            repeat col from 0 to maxcol
                oled.Position (col, row)
                oled.Char (rnd(127))
        oled.Update
        _fps++

PUB Demo_Wave(frames) | x, y, ydir
'' Draws a simple triangular wave
    ydir := 1
    y := 0
    repeat frames
        repeat x from 0 to XMAX
            if y == YMAX
                ydir := -1
            if y == 0
                ydir := 1
            y := y + ydir
            oled.Plot (x, y, 1)
        oled.Update
        _fps++
        oled.Clear

PUB Demo_Wander(reps) | x, y, d
'' Draws randomly wandering pixels
    _rndSeed := cnt
    x := XMAX/2
    y := YMAX/2
    repeat reps
        case d := rnd(4)
            1:
                x += 2
                if x > XMAX
                    x := 0
            2:
                x -= 2
                if x < 0
                    x := XMAX
            3:
                y += 2
                if y > YMAX
                    y := 0
            4:
                y -= 2
                if y < 0
                    y := YMAX
        oled.Plot (x, y, -1)
        oled.Update

PUB Cos(angle)                  'Cos angle is 13-bit ; Returns a 16-bit signed value
'' Return Cosine of angle
    result := sin(angle + $800)

PUB Sin(angle)                  'Sin angle is 13-bit ; Returns a 16-bit signed value

    result := angle << 1 & $FFE
    if angle & $800
       result := word[$F000 - result]
    else
       result := word[$E000 + result]
    if angle & $1000
       -result

PUB RND(upperlimit) | i       'Returns a random number between 0 and upperlimit

    i :=? _rndSeed
    i >>= 16
    i *= (upperlimit + 1)
    i >>= 16

    return i

PUB fps_mon
'' Sit in another cog and tell us (more or less) how many frames per second we're rendering
    ser.Position (0, 4)
    ser.Str (string("FPS: "))
    repeat
        time.MSleep (1000)
        ser.Position (5, 4)
        ser.Str (int.DecZeroed (_fps, 3))
        _fps := 0

PUB Setup

    repeat until ser.Start (115_200)
    time.MSleep(100)
    ser.Clear
    ser.Str (string("Serial terminal started", ser#CR, ser#LF))
    if oled.Start (WIDTH, HEIGHT, CS_PIN, SCK_PIN, SDA_PIN, DC_PIN, RES_PIN, @_framebuff)
        oled.Defaults
        oled.OscFreq (540)
        ser.Str (string("SSD1309 object started. Draw buffer @"))
        oled.FontSize (6, 8)
        oled.FontAddress (fnt5x8.BaseAddr)
        ser.Dec (oled.Address (-2))
'        ser.Hex (oled.Address (-2), 8)
    else
        ser.Str (string("SSD1309 object failed to start - halting"))
        oled.Stop
        time.MSleep (100)
        ser.Stop
        FlashLED (LED, 500)
    ser.Str (string(" - Ready.", ser#CR, ser#LF))
    _fps_mon_cog := cognew(fps_mon, @_fps_mon_stack)  'Start framerate monitor in another cog/core

PUB Stop

    ser.Position (0, 6)
    ser.Str (string("Press a key to power off", ser#CR, ser#LF))
    ser.CharIn

    oled.DisplayOff
    oled.Stop

    cogstop(_fps_mon_cog)

    ser.Position (0, 7)
    ser.Str (string("Halted", ser#CR, ser#LF))
    time.MSleep (1)
    ser.Stop
    FlashLED (LED, 100)

#include "lib.utility.spin"

DAT

    Beanie      byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $C0
                byte    $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $80, $80, $80, $80, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80
                byte    $80, $00, $00, $00, $80, $80, $80, $80, $C0, $C0, $C0, $C0, $C0, $E0, $E0, $E0
                byte    $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
                byte    $E0, $E0, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0F, $1F, $3F
                byte    $3F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $3F, $3F, $3F, $3F
                byte    $3F, $3F, $1F, $1F, $1E, $1E, $1E, $0E, $0E, $0E, $0E, $06, $06, $06, $F7, $FF
                byte    $FF, $F7, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $07
                byte    $07, $07, $07, $07, $07, $0F, $0F, $0F, $0F, $0F, $1F, $1F, $1F, $1F, $1F, $1F
                byte    $0F, $0F, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $80, $C0, $C0, $E0, $E0, $60, $70, $30, $30, $18, $18, $C8, $FF, $FF, $FF
                byte    $FF, $FF, $FF, $C8, $18, $18, $30, $30, $70, $60, $E0, $E0, $C0, $C0, $80, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $80, $C0, $E0, $F0, $F8, $FC, $FE, $7F
                byte    $3F, $0F, $07, $03, $01, $00, $00, $00, $00, $C0, $FC, $FF, $FF, $FF, $FF, $FF
                byte    $FF, $FF, $FF, $FF, $FF, $FC, $C0, $00, $00, $00, $00, $01, $03, $07, $0F, $3F
                byte    $7F, $FE, $FC, $F8, $F0, $E0, $C0, $80, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $80, $E0, $F8, $FC, $FF, $FF, $FF, $FF, $FF, $3F, $07, $01, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $FF, $FF, $FF, $FF
                byte    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F8, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $01, $07, $3F, $FF, $FF, $FF, $FF, $FF, $FC, $F8, $E0, $80, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $C0, $FC, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BF, $81, $80, $80, $80, $C0
                byte    $C0, $C0, $C0, $C0, $C0, $C0, $C0, $F0, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
                byte    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
                byte    $C0, $80, $80, $80, $81, $BF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FC, $C0, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $78, $FF, $FF, $FF, $FF, $FF, $FF, $CF, $CF, $CF, $CF, $CF, $C7, $87, $87, $87
                byte    $87, $87, $87, $87, $87, $87, $87, $07, $03, $03, $03, $03, $03, $03, $03, $03
                byte    $03, $03, $03, $03, $03, $03, $03, $03, $07, $87, $87, $87, $87, $87, $87, $87
                byte    $87, $87, $87, $C7, $CF, $CF, $CF, $CF, $CF, $FF, $FF, $FF, $FF, $FF, $FF, $78
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $01, $01, $03, $03, $03, $03, $03, $07, $07, $07, $07, $07, $07, $07
                byte    $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
                byte    $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
                byte    $07, $07, $07, $07, $07, $07, $07, $03, $03, $03, $03, $03, $01, $01, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

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
