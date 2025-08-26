#
# Makefile
#
CC = /home/meetyoo/t113/Tina-Linux/prebuilt/gcc/linux-x86/arm/toolchain-sunxi-musl/toolchain/bin/arm-openwrt-linux-gcc
LVGL_DIR_NAME ?= lvgl
LVGL_DIR ?= ${shell pwd}
CFLAGS ?= -O3 -g0 -I$(LVGL_DIR)/ -Wall -Wshadow -Wundef -Wmissing-prototypes \
		   -Wno-discarded-qualifiers -Wall -Wextra -Wno-unused-function \
		   -Wno-error=strict-prototypes -Wpointer-arith -fno-strict-aliasing \
		   -Wno-error=cpp -Wuninitialized -Wmaybe-uninitialized -Wno-unused-parameter \
		   -Wno-missing-field-initializers -Wtype-limits -Wsizeof-pointer-memaccess \
		   -Wno-format-nonliteral -Wno-cast-qual -Wunreachable-code -Wno-switch-default \
		   -Wreturn-type -Wmultichar -Wformat-security -Wno-ignored-qualifiers \
		   -Wno-error=pedantic -Wno-sign-compare -Wno-error=missing-prototypes \
		   -Wdouble-promotion -Wclobbered -Wdeprecated -Wempty-body -Wtype-limits \
		   -Wshift-negative-value -Wstack-usage=2048 -Wno-unused-value \
		   -Wno-unused-parameter -Wno-missing-field-initializers -Wuninitialized \
		   -Wmaybe-uninitialized -Wall -Wextra -Wno-unused-parameter \
		   -Wno-missing-field-initializers -Wtype-limits -Wsizeof-pointer-memaccess \
		   -Wno-format-nonliteral -Wpointer-arith -Wno-cast-qual -Wmissing-prototypes \
		   -Wunreachable-code -Wno-switch-default -Wreturn-type -Wmultichar \
		   -Wno-discarded-qualifiers -Wformat-security -Wno-ignored-qualifiers -Wno-sign-compare 
LDFLAGS ?= -lm

# 输出目录
BUILD_DIR = build
BIN_DIR = bin
BIN = $(BIN_DIR)/lv_demo

#Collect the files to compile
MAINSRC = ./main.c

include $(LVGL_DIR)/lvgl/lvgl.mk
include $(LVGL_DIR)/lv_drivers/lv_drivers.mk

# CSRCS +=$(LVGL_DIR)/mouse_cursor_icon.c 

OBJEXT ?= .o

# 修改对象文件路径到 build 目录
AOBJS = $(ASRCS:%.S=$(BUILD_DIR)/%$(OBJEXT))
COBJS = $(CSRCS:%.c=$(BUILD_DIR)/%$(OBJEXT))
MAINOBJ = $(MAINSRC:%.c=$(BUILD_DIR)/%$(OBJEXT))

SRCS = $(ASRCS) $(CSRCS) $(MAINSRC)
OBJS = $(AOBJS) $(COBJS)

# 创建目录的函数
define make-dir
@if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi
endef

all: default

# 编译规则 - 确保目录存在
$(BUILD_DIR)/%.o: %.c
	$(call make-dir)
	@$(CC) $(CFLAGS) -c $< -o $@
	@echo "CC $< -> $@"

$(BUILD_DIR)/%.o: %.S
	$(call make-dir)
	@$(CC) $(CFLAGS) -c $< -o $@
	@echo "CC $< -> $@"

default: $(BIN_DIR) $(BUILD_DIR) $(AOBJS) $(COBJS) $(MAINOBJ)
	$(CC) -o $(BIN) $(MAINOBJ) $(AOBJS) $(COBJS) $(LDFLAGS)
	@echo "Build complete: $(BIN)"

# 创建输出目录
$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

clean: 
	rm -rf $(BUILD_DIR) $(BIN_DIR)
	@echo "Clean complete"

.PHONY: all default clean