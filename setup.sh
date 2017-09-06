cd devicetree
make
make install
echo ML-CAPE > /sys/devices/bone_capemgr.8/slots
cat /sys/devices/bone_capemgr.8/slots
