
DTS_SRC=ML-CAPE.dts
DTS_VER=00A0
DTS_BIN=$(DTS_SRC)-$(DTS_VER).dtbo
FIRMWARE_DIR=/lib/firmware

default: overlay

overlay:
	dtc -O dtb -o $(DTS_BIN) -b 0 -@ $(DTS_SRC)

install:
	cp $(DTS_BIN) $(FIRMWARE_DIR)/$(DTS_BIN)
