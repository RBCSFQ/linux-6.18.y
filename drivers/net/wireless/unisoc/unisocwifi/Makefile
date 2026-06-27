# SPDX-License-Identifier: GPL-2.0
#
# Unisoc UWE5621 WIFI driver (sprdwl_ng)
#

ccflags-y += -Wno-attribute-warning
ccflags-y += -DUWE5621_FTR
ccflags-y += -DACS_SUPPORT -DRX_HW_CSUM
ccflags-y += -DWMMAC_WFA_CERTIFICATION
ccflags-y += -DCOMPAT_SAMPILE_CODE
ccflags-y += -DATCMD_ASSERT
ccflags-y += -DTCPACK_DELAY_SUPPORT
ccflags-y += -DSPLIT_STACK
ccflags-y += -DPPPOE_LLC_SUPPORT
ccflags-y += -DSYNC_DISCONNECT
ccflags-y += -DWL_CONFIG_DEBUG

# Include path for BSP headers
ccflags-y += -I$(srctree)/drivers/net/wireless/unisoc/unisocwcn/include/

MODULE_NAME := sprdwl_ng

obj-$(CONFIG_SPRDWL_NG) += $(MODULE_NAME).o

$(MODULE_NAME)-objs += main.o cfg80211.o txrx.o cmdevt.o npi.o msg.o work.o vendor.o \
			tcp_ack.o mm.o reorder.o wl_core.o tx_msg.o rx_msg.o \
			wl_intf.o qos.o dbg_ini_util.o reg_domain.o \
			defrag.o ibss.o nan.o tracer.o rf_marlin3.o \
			rtt.o api_version.o rnd_mac_addr.o debug.o
