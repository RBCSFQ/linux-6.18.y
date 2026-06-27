# SPDX-License-Identifier: GPL-2.0
#
# Unisoc WCN BSP driver (UWE5621 chip management)
#

ccflags-y += -D__linux__
ccflags-y += -DCONFIG_WCN_SDIO
ccflags-y += -DCONFIG_WCN_SLP
ccflags-y += -DCONFIG_WCN_SWD
ccflags-y += -DCONFIG_WCN_BOOT
ccflags-y += -DCONFIG_WCN_UTILS
ccflags-y += -DCONFIG_CHECK_DRIVER_BY_CHIPID
ccflags-y += -DCONFIG_SDIO_TX_ADMA_MODE
ccflags-y += -DCONFIG_SDIO_RX_ADMA_MODE
ccflags-y += -DCONFIG_SDIO_INBAND_INT
ccflags-y += -DCONFIG_SDIO_BLKSIZE_512
ccflags-y += -DCONFIG_BT_WAKE_HOST_EN
ccflags-y += -DCONFIG_WCN_PARSE_DTS

# Include paths
ccflags-y += -I$(src)/include/
ccflags-y += -I$(src)/platform/
ccflags-y += -I$(src)/platform/rf/

MODULE_NAME := uwe5621_bsp_sdio

obj-$(CONFIG_RK_WIFI_DEVICE_UWE5621) += $(MODULE_NAME).o

$(MODULE_NAME)-y += wcn_bus.o \
			platform/wcn_boot.o \
			platform/wcn_dump.o \
			platform/bufring.o \
			platform/wcn_txrx.o \
			platform/wcn_op.o \
			platform/wcn_parn_parser.o \
			platform/rdc_debug.o \
			platform/wcn_log.o \
			platform/wcn_misc.o \
			platform/wcn_procfs.o \
			platform/loopcheck.o \
			platform/wcn_swd_dp.o \
			platform/mem_pd_mgr.o \
			sdio/sdiohal_main.o \
			sdio/sdiohal_common.o \
			sdio/sdiohal_tx.o \
			sdio/sdiohal_rx.o \
			sdio/sdio_v3.o \
			sdio/sdiohal_ctl.o \
			sleep/sdio_int.o \
			sleep/slp_mgr.o \
			sleep/slp_sdio.o \
			sleep/slp_test.o
