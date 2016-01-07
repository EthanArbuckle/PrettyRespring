export THEOS_DEVICE_IP = localhost
export THEOS_DEVICE_PORT = 2222

include theos/makefiles/common.mk

TWEAK_NAME = PrettyRespring
PrettyRespring_FILES = Tweak.xm $(wildcard *mm)
PrettyRespring_FRAMEWORKS = UIKit QuartzCore
PrettyRespring_PRIVATE_FRAMEWORKS = IOSurface
PrettyRespring_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"

SUBPROJECTS += prettyrespringbackboardd

include $(THEOS_MAKE_PATH)/aggregate.mk
