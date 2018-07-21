include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WebRestore
WebRestore_FILES = Tweak.xm
WebRestore_FRAMEWORKS = UIKit CoreGraphics QuartzCore WebKit
WebRestore_LDFLAGS = -lIOKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
