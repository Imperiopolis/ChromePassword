TWEAK_NAME = ChromePassword
ChromePassword_FILES = Tweak.x CPTLDParser.m 
ChromePassword_FRAMEWORKS = Foundation UIKit QuartzCore

ADDITIONAL_CFLAGS = -std=c99
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 6.0

ARCHS = armv7
SDKVERSION := 6.1
INCLUDE_SDKVERSION := 6.1
TARGET_IPHONEOS_DEPLOYMENT_VERSION := 3.0

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
