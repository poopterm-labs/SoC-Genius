# Repository-level dispatcher. Each variant starts its own top-level Theos build.
.PHONY: all package package64 package32 package-all clean clean64 clean32 clean-all

all: package

package: package64

package64:
	env -u MAKELEVEL $(MAKE) -C SoCGenius64 package THEOS_PACKAGE_DIR=../packages/64

package32:
	env -u MAKELEVEL $(MAKE) -C SoCGenius32 package THEOS_PACKAGE_DIR=../packages/32

package-all: package64 package32

clean: clean64

clean64:
	env -u MAKELEVEL $(MAKE) -C SoCGenius64 clean THEOS_PACKAGE_DIR=../packages/64

clean32:
	env -u MAKELEVEL $(MAKE) -C SoCGenius32 clean THEOS_PACKAGE_DIR=../packages/32

clean-all: clean64 clean32
