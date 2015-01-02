#define __SFR_OFFSET 0

#include <avr/io.h>

.org 0

start:
sbi DDRB, DDB5

loop:
  rcall invert
  rcall spin
rjmp loop

invert:
  in  r16, PORTB
  ldi r17, (1 << PORTB5)
  eor r16, r17
  out PORTB, r16
ret

spin:
  ldi r16, 0x00
  ldi r17, 0x35
  ldi r18, 0x0c

  _spin:
    subi r16, 0x01
    sbci r17, 0x00
    sbci r18, 0x00
  brne _spin
ret
