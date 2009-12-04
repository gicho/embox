export
ROOT_DIR   := $(CURDIR)
BIN_DIR     = $(ROOT_DIR)/bin
OBJ_DIR     = $(ROOT_DIR)/obj
SRC_DIR     = $(ROOT_DIR)/src
SCRIPTS_DIR = $(ROOT_DIR)/scripts
INCLUDE_DIR = $(ROOT_DIR)/include
RM          = rm -rf
EDITOR      = vim
MAKE        += --no-print-directory

OBJ_LIST    = $(OBJ_DIR)/$(BUILD)/objects.lst

ifeq ($(shell [ -f scripts/autoconf ] && echo YES),YES)
    DEFAULT_CONF =
else
    DEFAULT_CONF = .in
endif

include $(SCRIPTS_DIR)/autoconf$(DEFAULT_CONF)

ifeq ($(SIMULATION_TRG),y)
BUILD = sim
endif
ifeq ($(DEBUG_TRG),y)
BUILD = debug
endif
ifeq ($(RELEASE_TRG),y)
BUILD = release
endif
ifeq ($(DOXYGEN_TRG),y)
BUILD = docs
endif

CC      = $(CC_PACKET)-gcc
OD_TOOL = $(CC_PACKET)-objdump
OC_TOOL = $(CC_PACKET)-objcopy

.PHONY: mkdir build checksum all clean config xconfig menuconfig mconfig

all: mkdir build checksum

mkdir:
	@if [ -e .config -o -e .config2 ]; \
	then \
	    echo Start; \
	else \
	    echo "Building default configuration (try 'make x[menu]config')"; \
	    cp $(SCRIPTS_DIR)/autoconf.in $(SCRIPTS_DIR)/autoconf; \
	    cp $(SCRIPTS_DIR)/autoconf.h.in $(SCRIPTS_DIR)/autoconf.h; \
	fi;
	@test -d $(BIN_DIR)          || mkdir -p $(BIN_DIR)
	@test -d $(OBJ_DIR)          || mkdir -p $(OBJ_DIR)
	@test -d $(OBJ_DIR)/$(BUILD) || mkdir -p $(OBJ_DIR)/$(BUILD)

build:
	@declare -x MAKEOP=all; $(MAKE) --directory=src all

checksum:
#	@$(MAKE) --directory=scripts/md5_checksummer
#	@if [ $(SIGN_CHECKSUM) == y ]; \
#	then \
#	    $(SCRIPTS_DIR)/ConfigBuilder/Misc/checksum.py -o $(OC_TOOL) -d $(BIN_DIR) -t $(TARGET) --build=$(BUILD); \
#	    declare -x MAKEOP=all G_DIRS=`cat include_dirs.lst`; $(MAKE) --directory=src all; \
#	else \
#	    $(SCRIPTS_DIR)/ConfigBuilder/Misc/checksum.py -o $(OC_TOOL) -d $(BIN_DIR) -t $(TARGET) --build=$(BUILD) --clean; \
#	fi;

clean:
	@declare -x MAKEOP=clean; $(MAKE) --directory=src clean
	@$(RM) $(BIN_DIR) $(OBJ_DIR) .config.old docs/
	@$(SCRIPTS_DIR)/ConfigBuilder/Misc/checksum.py -o $(OD_TOOL) -d $(BIN_DIR) -t $(TARGET) --build=$(BUILD) --clean

clean_all: clean
	@$(RM) .config .config2 $(SCRIPTS_DIR)/autoconf $(SCRIPTS_DIR)/autoconf.h
	@ln -sf -T asm-sparc include/asm

xconfig:
	@$(SCRIPTS_DIR)/configure.py --mode=tk

menuconfig:
	@if [ ! -e $(SCRIPTS_DIR)/autoconf ]; \
	then \
	    cp $(SCRIPTS_DIR)/autoconf.in $(SCRIPTS_DIR)/autoconf; \
	    cp $(SCRIPTS_DIR)/autoconf.h.in $(SCRIPTS_DIR)/autoconf.h; \
	fi;
	@$(EDITOR) $(SCRIPTS_DIR)/autoconf
	@$(EDITOR) $(SCRIPTS_DIR)/autoconf.h
	@$(SCRIPTS_DIR)/configure.py --mode=menu > /dev/null 2>&1

config:
	@echo "Oops! Try edit config file by hand or use \"make x(menu)config\" and have a lot of fun."

mconfig:
	@$(SCRIPTS_DIR)/configure.py --mode=qt > /dev/null 2>&1
