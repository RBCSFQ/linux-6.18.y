# SPDX-License-Identifier: GPL-2.0
#
# Unisoc UWE5621 Bluetooth TTY over SDIO driver
#

ccflags-y += -Wno-implicit-fallthrough
ccflags-y += -I$(srctree)/drivers/net/wireless/unisoc/unisocwcn/include/

sprdbt_tty-y := tty.o rfkill.o lpm.o woble.o alignment/sitm.o dump.o

obj-$(CONFIG_TTY_OVERY_SDIO) += sprdbt_tty.o
