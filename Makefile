#CROSS_COMPILE?=arm-arago-linux-gnueabi-

INCDIR_APP_LOADER?=/usr/include/pruss
INCDIR=./software/include

CFLAGS+= -Wall -I$(INCDIR_APP_LOADER) -I$(INCDIR) -D__DEBUG -O2 -mtune=cortex-a8 -march=armv7-a
LDFLAGS+=-lprussdrv  
OBJDIR=obj
TARGET=jiminy.elf
ASM=firmware/pulsewidth_sensors.p
BIN=pulsewidth_sensors.bin
BINDIR=firmware
VPATH=software

default: $(TARGET) $(BIN)
all: $(TARGET) $(BIN)

_OBJ = PRU_memAcc_DDR_sharedRAM.o ultrasonic.o pru.o
OBJ = $(patsubst %,$(OBJDIR)/%,$(_OBJ))

$(OBJDIR)/%.o: %.cpp #$(DEPS)
	@mkdir -p obj
	$(CROSS_COMPILE)g++ $(CFLAGS) -c -o $@ $<

$(TARGET): $(OBJ)
	$(CROSS_COMPILE)g++ $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(BIN): $(ASM)
	pasm -b $^ 
	mv $@ $(BINDIR)

.PHONY: clean

clean:
	rm -rf $(OBJDIR)/ *~  $(INCDIR_APP_LOADER)/*~  $(TARGET) $(BINDIR)/$(BIN)
