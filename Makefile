# This Makefile is to build and copy native LV2 dependencies

PWD=$(shell pwd)

WAF_DEBUG=-d
ANDROID_NDK=/home/$(USER)/Android/Sdk/ndk/21.2.6472646/
LLVM_TOOLCHAIN=$(ANDROID_NDK)/toolchains/llvm/prebuilt/linux-x86_64
ANDROID_TOOLCHAIN=$(ANDROID_NDK)/toolchains/$(ABI_COMPLEX)-4.9/prebuilt/linux-x86_64
ABIS=armeabi-v7a arm64-v8a x86 x86_64

# for build-single
DIST_ABI_PATH=$(PWD)/dist/$(ABI_FORMAL)
PKG_CONFIG_PATH=$(DIST_ABI_PATH)/lib/pkgconfig:$(PWD)/cerbero-artifacts/outputs/$(ABI_FORMAL)/lib/pkgconfig
CC=$(LLVM_TOOLCHAIN)/bin/$(ABI_CLANG)29-clang
CXX=$(LLVM_TOOLCHAIN)/bin/$(ABI_CLANG)29-clang++
LD=$(ANDROID_TOOLCHAIN)/bin/$(ABI_COMPLEX)-ld
#CFLAGS=--sysroot='$(ANDROID_NDK)/sysroot' -I'$(ANDROID_NDK)/sysroot/usr/include/' -DANDROID
CFLAGS='-DANDROID'

TOP=`pwd`

all: build

.PHONY:
download-ndk: $(ANDROID_NDK)

$(ANDROID_NDK):
	wget https://dl.google.com/android/repository/android-ndk-r20b-linux-x86_64.zip >/dev/null
	unzip android-ndk-r20b-linux-x86_64.zip >/dev/null
	mkdir -p $(ANDROID_NDK)
	mv android-ndk-r20b/* $(ANDROID_NDK)

.PHONY:
package: build package-zip package-prefab

.PHONY:
build: download-ndk build-cerbero-deps copy-eigen patch-guitarix build-lv2-stuff

.PHONY:
build-cerbero-deps:
	make -C cerbero-artifacts

.PHONY:
clean: clean-lv2-stuff clean-cerbero-deps

clean-cerbero-deps:
	make -C cerbero-artifacts clean

.PHONY:
prepare:
	make -C cerbero-artifacts prepare

.PHONY:
copy-eigen: .eigen.stamp

.eigen.stamp:
	for a in $(ABIS) ; do \
		cp -R eigen/Eigen dist/$$a/include ; \
	done ; \
	touch .eigen.stamp

.PHONY:
patch-guitarix: guitarix/patch.stamp

guitarix/patch.stamp:
	cd guitarix && patch -i ../aap-guitarix.patch -p1 && touch patch.stamp

.PHONY:
build-lv2-stuff:
	make ABI_FORMAL=armeabi-v7a ABI_SIMPLE=armv7  ABI_CLANG=armv7a-linux-androideabi ABI_COMPLEX=arm-linux-androideabi build-single-abi
	make ABI_FORMAL=arm64-v8a ABI_SIMPLE=arm64  ABI_CLANG=aarch64-linux-android    ABI_COMPLEX=aarch64-linux-android build-single-abi
	make ABI_FORMAL=x86 ABI_SIMPLE=x86    ABI_CLANG=i686-linux-android       ABI_COMPLEX=i686-linux-android build-single-abi
	make ABI_FORMAL=x86_64 ABI_SIMPLE=x86-64 ABI_CLANG=x86_64-linux-android     ABI_COMPLEX=x86_64-linux-android build-single-abi

clean-lv2-stuff:
	make ABI_FORMAL=armeabi-v7a clean-single-abi
	make ABI_FORMAL=arm64-v8a clean-single-abi
	make ABI_FORMAL=x86 clean-single-abi
	make ABI_FORMAL=x86_64 clean-single-abi

.PHONY:
build-single-abi:
	mkdir -p build/$(ABI_FORMAL)
	make MODULE=serd MODULE_MAJOR=0 MODULE_VER=0.30.3 MODULE_OPTIONS="--no-utils" build-single
	make MODULE=sord MODULE_MAJOR=0 MODULE_VER=0.16.4 MODULE_OPTIONS="--no-utils" build-single
	make MODULE=lv2 MODULE_MAJOR=0 MODULE_OPTIONS="--copy-headers --no-plugins" SRCDIR=. build-single-no-soname-opt
	make MODULE=sratom MODULE_MAJOR=0 MODULE_VER=0.6.4 build-single
	make MODULE=lilv MODULE_MAJOR=0 MODULE_VER=0.24.7 MODULE_OPTIONS="--no-utils" build-single
	make MODULE=mda-lv2 MODULE_MAJOR=0 SRCDIR=. build-single-no-soname-opt
	make MODULE=guitarix EXTRA_ENV="GX_PYTHON_WRAPPER=0" WAF_DEBUG=" " MODULE_MAJOR=0 NO_SED=1 CXXFLAGS="-I$(DIST_ABI_PATH)/include" LDFLAGS="-L$(DIST_ABI_PATH)/lib -lzita-convolver -lzita-resampler" MODULE_OPTIONS="--no-standalone --no-lv2-gui --no-avahi --no-avahi --no-bluez --disable-sse" SRCDIR=trunk build-single-no-soname-opt

.PHONY:
clean-single-abi:
	make MODULE=guitarix SRCDIR=trunk clean-single-detail
	make MODULE=mda-lv2 clean-single
	make MODULE=lilv clean-single
	make MODULE=lv2 clean-single
	make MODULE=sratom clean-single
	make MODULE=sord clean-single
	make MODULE=serd clean-single

.PHONY:
build-single:
	make LDFLAGS="-Wl,-soname,lib$(MODULE)-$(MODULE_MAJOR).so" SRCDIR=. build-single-no-soname-opt
	mv $(DIST_ABI_PATH)/lib/lib$(MODULE)-$(MODULE_MAJOR).so.$(MODULE_VER) $(DIST_ABI_PATH)/lib/lib$(MODULE)-$(MODULE_MAJOR).so
	rm $(DIST_ABI_PATH)/lib/lib$(MODULE)-$(MODULE_MAJOR).so.0

.PHONY:
build-single-no-soname-opt:
	echo "Building $(MODULE) for $(ABI_FORMAL) ($(ABI_COMPLEX)) ..."
	mkdir -p build/$(ABI_FORMAL)/$(MODULE)
	cp -R $(MODULE)/$(SRCDIR)/* build/$(ABI_FORMAL)/$(MODULE)/
	cd build/$(ABI_FORMAL)/$(MODULE) && \
	PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" \
	CC="$(CC)" \
	CXX="$(CXX)" \
	LD="$(LD)" \
	CFLAGS="$(CFLAGS)" \
	LDFLAGS="-landroid $(LDFLAGS)" \
	$(EXTRA_ENV) ./waf $(MODULE_OPTIONS) --prefix=$(DIST_ABI_PATH) configure && \
	if '$(NO_SED)' == '' ; then \
	echo "autowaf has a horrible issue that it moves away all those required external CFLAGS and it's used everywhere, meaning that making changes to it will mess the future builds. As a workaround, we hack those configure results" && \
	sed -i -e "s/CFLAGS = \[/CFLAGS = \[$(CFLAGS), /" build/c4che/_cache.py ; \
	fi && \
	./waf $(WAF_DEBUG) $(MODULE_OPTIONS) --prefix=$(DIST_ABI_PATH) build install && \
	cd ../../.. || exit 1

.PHONY:
clean-single:
	make MODULE=$(MODULE) SRCDIR=. clean-single-detail

.PHONY:
clean-single-detail:
	# It looks too verbose steps, but ensures that we don't accidentaly remove unexpected directory (e.g. what happens if ABI_FORMAL and MODULE are empty?)
	pushd . && cd build/$(ABI_FORMAL)/$(MODULE)/$(SRCDIR) && ./waf clean && popd && rm -rf build/$(ABI_FORMAL)/$(MODULE)/$(SRCDIR)

.PHONY:
package-zip:
	rm -f android-lv2-binaries.zip
	zip -r android-lv2-binaries.zip dist -x '*/doc/*' -x '*/man/*' -x '*/lv2specgen/*'

.PHONY:
package-prefab:
	cd prefab && ./build.sh || exit 1 && cd ..

