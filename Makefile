PRG            = flash
OBJ            = flash.o
PROGRAMMER     = arduino
PORT           = /dev/tty.usbmodem1411
MCU_TARGET     = atmega328p
AVRDUDE_TARGET = atmega328p
OPTIMIZE       = -Os
DEFS           =
LIBS           =

HZ = 16000000

override CFLAGS  = -g -DF_CPU=$(HZ) -Wall $(OPTIMIZE) -mmcu=$(MCU_TARGET) $(DEFS) -Wl,-Map,$(PRG).map -nostartfiles
override ASFLAGS = -g -DF_CPU=$(HZ) -Wall $(OPTIMIZE) -mmcu=$(MCU_TARGET) $(DEFS)

CC = avr-gcc
OBJCOPY = avr-objcopy
OBJDUMP = avr-objdump

all: $(PRG).elf lst text

clean:
	rm -rf *.o $(PRG).elf *.eps *.png *.pdf *.bak *.hex *.bin *.srec
	rm -rf *.lst *.map *.gdb $(EXTRA_CLEAN_FILES)

lst: $(PRG).lst

%.lst: %.elf
	$(OBJDUMP) -h -S $< > $@

%.elf: $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)

# Rules for building the .text rom images

text: hex bin srec

hex:  $(PRG).hex
bin:  $(PRG).bin
srec: $(PRG).srec

%.hex: %.elf
	$(OBJCOPY) -j .text -j .data -O ihex $< $@

%.bin: %.elf
	$(OBJCOPY) -j .text -j .data -O binary $< $@

%.srec: %.elf
	$(OBJCOPY) -j .text -j .data -O srec $< $@

# Rules for building the .eeprom rom images

eeprom: ehex ebin esrec

ehex:  $(PRG)_eeprom.hex
ebin:  $(PRG)_eeprom.bin
esrec: $(PRG)_eeprom.srec

%_eeprom.hex: %.elf
	$(OBJCOPY) -j .eeprom --change-section-lma .eeprom=0 -O ihex $< $@

%_eeprom.bin: %.elf
	$(OBJCOPY) -j .eeprom --change-section-lma .eeprom=0 -O binary $< $@

%_eeprom.srec: %.elf
	$(OBJCOPY) -j .eeprom --change-section-lma .eeprom=0 -O srec $< $@

# command to program chip (invoked by running "make install")

install:  $(PRG).hex
	avrdude -p $(AVRDUDE_TARGET) -c $(PROGRAMMER) -P $(PORT) -v \
  -U flash:w:$(PRG).hex

fuse:
	avrdude -p $(AVRDUDE_TARGET) -c $(PROGRAMMER) -P $(PORT) -v \
	-U lfuse:w:0xc6:m -U hfuse:w:0xd9:m 	

# debugging stuff

ddd: $(PRG).gdb
	ddd --debugger "avr-gdb -x $(PRG).gdb"

gdbserver: $(PRG).gdb
	simavr -mcu $(MCU_TARGET) -g

%.gdb: %.elf
	@echo "file $<" > $@
	@echo "target remote localhost:1234" >> $@
	@echo "break main"                   >> $@
