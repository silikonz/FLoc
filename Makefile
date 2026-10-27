TARGET = iphone:clang:latest:14.0

ARCHS = arm64 arm64e

#INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FLoc

FLoc_FILES = Tweak.xm
FLoc_FRAMEWORKS = CoreLocation
FLoc_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
