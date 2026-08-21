TARGET = iphone:clang:latest:15.0

ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = fmfn

fmfn_FILES = Tweak.xm
fmfn_CFLAGS = -fobjc-arc
fmfn_PRIVATE_FRAMEWORKS = BulletinBoard

include $(THEOS_MAKE_PATH)/tweak.mk
