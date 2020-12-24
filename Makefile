# This Makefile is to build and copy native LV2 dependencies

# Variables

## Customizible variables

# e.g. make PACKAGING_DO_CLEAN=0 package-guitarix
PACKAGING_DO_CLEAN=1

ANDROID_NDK=$(ANDROID_SDK_ROOT)/ndk/21.3.6528147/
HOST_ARCH=`uname | tr '[:upper:]' '[:lower:]'`

ABIS=armeabi-v7a arm64-v8a x86 x86_64


## Internal variables

PWD=$(shell pwd)

WAF_DEBUG=-d
LLVM_TOOLCHAIN=$(ANDROID_NDK)/toolchains/llvm/prebuilt/$(HOST_ARCH)-x86_64
ANDROID_TOOLCHAIN=$(ANDROID_NDK)/toolchains/$(ABI_COMPLEX)-4.9/prebuilt/$(HOST_ARCH)-x86_64

ABI_LD=$(ABI_COMPLEX)

SSE_CLANG_OPT=

# for build-single
DIST_ABI_PATH=$(PWD)/dist/$(ABI_FORMAL)
REF_ABI_PATH=$(PWD)/ref/$(ABI_FORMAL)
PKG_CONFIG_PATH=$(DIST_ABI_PATH)/lib/pkgconfig:$(REF_ABI_PATH)/lib/pkgconfig:$(PWD)/cerbero-artifacts/outputs/$(ABI_FORMAL)/lib/pkgconfig
CC=$(LLVM_TOOLCHAIN)/bin/$(ABI_CLANG)29-clang
CXX=$(LLVM_TOOLCHAIN)/bin/$(ABI_CLANG)29-clang++
LD=$(ANDROID_TOOLCHAIN)/bin/$(ABI_LD)-ld
#CFLAGS=--sysroot='$(ANDROID_NDK)/sysroot' -I'$(ANDROID_NDK)/sysroot/usr/include/' -DANDROID
CFLAGS='-DANDROID'

TOP=`pwd`



# Targets

all: build-all

## build targets

download-ndk: $(ANDROID_NDK)

$(ANDROID_NDK):
	wget https://dl.google.com/android/repository/android-ndk-r21b-$(HOST_ARCH)-x86_64.zip >/dev/null
	unzip android-ndk-r21b-$(HOST_ARCH)-x86_64.zip >/dev/null
	mkdir -p $(ANDROID_NDK)
	mv android-ndk-r21b/* $(ANDROID_NDK)

build-all: build-lv2-sdk build-guitarix

build-lv2-sdk: download-ndk  build-lv2-sdk-local

build-libsndfile-deps: # directly called by package-libsndfile
	make -C cerbero-artifacts build-libsndfile copy-as-dist

build-guitarix: download-ndk  build-guitarix-deps  copy-eigen  patch-guitarix \
		build-guitarix-local

build-guitarix-deps: build-lv2-sdk
	mkdir -p ref
	cp -R dist/* ref/
	make clean-local-dist
	make -C cerbero-artifacts build-guitarix-deps copy-as-dist

.PHONY:
clean: clean-lv2-stuff clean-cerbero-deps

clean-cerbero-deps:
	make -C cerbero-artifacts clean

.PHONY:
prepare:
	make -C cerbero-artifacts prepare

copy-eigen: .eigen.stamp

.eigen.stamp:
	for a in $(ABIS) ; do \
		cp -R eigen/Eigen dist/$$a/include ; \
	done ; \
	touch .eigen.stamp

patch-guitarix: guitarix/patch.stamp

guitarix/patch.stamp:
	cd guitarix && patch -i ../aap-guitarix.patch -p1 && touch patch.stamp

build-lv2-sdk-local:
	make WAF_BUILD_TARGET=waf-lv2-sdk waf-for-all-abi

build-guitarix-local:
	make WAF_BUILD_TARGET=waf-guitarix waf-for-all-abi

waf-for-all-abi:
	make ABI_FORMAL=armeabi-v7a ABI_SIMPLE=armv7  ABI_CLANG=armv7a-linux-androideabi ABI_COMPLEX=arm-linux-androideabi $(WAF_BUILD_TARGET) || exit 1
	make ABI_FORMAL=arm64-v8a ABI_SIMPLE=arm64  ABI_CLANG=aarch64-linux-android    ABI_COMPLEX=aarch64-linux-android $(WAF_BUILD_TARGET) || exit 1
	make ABI_FORMAL=x86 ABI_SIMPLE=x86 ABI_CLANG=i686-linux-android ABI_LD=i686-linux-android ABI_COMPLEX=x86 SSE_CLANG_OPT=-mfxsr $(WAF_BUILD_TARGET) || exit 1
	make ABI_FORMAL=x86_64 ABI_SIMPLE=x86-64 ABI_CLANG=x86_64-linux-android ABI_LD=x86_64-linux-android ABI_COMPLEX=x86_64 SSE_CLANG_OPT=-mfxsr $(WAF_BUILD_TARGET) || exit 1

clean-lv2-stuff:
	make ABI_FORMAL=armeabi-v7a clean-single-abi
	make ABI_FORMAL=arm64-v8a clean-single-abi
	make ABI_FORMAL=x86 clean-single-abi
	make ABI_FORMAL=x86_64 clean-single-abi

waf-lv2-sdk:
	mkdir -p build/$(ABI_FORMAL)
	make MODULE=serd MODULE_MAJOR=0 MODULE_VER=0.30.7 MODULE_OPTIONS="--no-utils" build-single || exit 1
	make MODULE=sord MODULE_MAJOR=0 MODULE_VER=0.16.7 MODULE_OPTIONS="--no-utils" build-single || exit 1
	make MODULE=lv2 MODULE_MAJOR=0 MODULE_OPTIONS="--copy-headers --no-plugins" SRCDIR=. build-single-no-soname-opt || exit 1
	make MODULE=sratom MODULE_MAJOR=0 MODULE_VER=0.6.7 build-single || exit 1
	make MODULE=lilv MODULE_MAJOR=0 MODULE_VER=0.24.11 MODULE_OPTIONS="--no-utils" build-single || exit 1
	make MODULE=mda-lv2 MODULE_MAJOR=0 SRCDIR=. build-single-no-soname-opt || exit 1

waf-guitarix:
	# zita-resampler is hack here...
	make MODULE=guitarix EXTRA_ENV="GX_PYTHON_WRAPPER=0" WAF_DEBUG=" " MODULE_MAJOR=0 NO_SED=1 CXXFLAGS="$(SSE_CLANG_OPT) -I$(DIST_ABI_PATH)/include -I$(REF_ABI_PATH)/include -I$(PWD)/guitarix/trunk/src/zita-resampler-1.1.0" LDFLAGS="-L$(DIST_ABI_PATH)/lib -L$(REF_ABI_PATH)/lib" MODULE_OPTIONS="--no-standalone --no-lv2-gui --no-avahi --no-avahi --no-bluez --disable-sse" SRCDIR=trunk build-single-no-soname-opt

clean-single-abi:
	make MODULE=guitarix SRCDIR=trunk clean-single-detail
	make MODULE=mda-lv2 clean-single
	make MODULE=lilv clean-single
	make MODULE=lv2 clean-single
	make MODULE=sratom clean-single
	make MODULE=sord clean-single
	make MODULE=serd clean-single

build-single:
	make LDFLAGS="-Wl,-soname,lib$(MODULE)-$(MODULE_MAJOR).so" SRCDIR=. build-single-no-soname-opt
	mv $(DIST_ABI_PATH)/lib/lib$(MODULE)-$(MODULE_MAJOR).so.$(MODULE_VER) $(DIST_ABI_PATH)/lib/lib$(MODULE)-$(MODULE_MAJOR).so
	rm $(DIST_ABI_PATH)/lib/lib$(MODULE)-$(MODULE_MAJOR).so.0

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
	LDFLAGS="-static-libstdc++ -landroid $(LDFLAGS)" \
	$(EXTRA_ENV) ./waf $(MODULE_OPTIONS) --prefix=$(DIST_ABI_PATH) configure && \
	if '$(NO_SED)' == '' ; then \
	echo "autowaf has a horrible issue that it moves away all those required external CFLAGS and it's used everywhere, meaning that making changes to it will mess the future builds. As a workaround, we hack those configure results" && \
	sed -i -e "s/CFLAGS = \[/CFLAGS = \[$(CFLAGS), /" build/c4che/_cache.py ; \
	fi && \
	./waf $(WAF_DEBUG) $(MODULE_OPTIONS) --prefix=$(DIST_ABI_PATH) build install && \
	cd ../../.. || exit 1


## clean targets

clean-single:
	make MODULE=$(MODULE) SRCDIR=. clean-single-detail

clean-single-detail:
	# It looks too verbose steps, but ensures that we don't accidentaly remove unexpected directory (e.g. what happens if ABI_FORMAL and MODULE are empty?)
	pushd . && cd build/$(ABI_FORMAL)/$(MODULE)/$(SRCDIR) && ./waf clean && popd && rm -rf build/$(ABI_FORMAL)/$(MODULE)/$(SRCDIR)

clean-local-dist:
	if [ '$(PACKAGING_DO_CLEAN)' = '1' ] ; then \
		rm -rf dist/* ; \
	fi

## packaging targets

package-all: package-aap package-libsndfile package-guitarix

package-aap:
	# ensure that clean-local-dist is called every time
	make clean-local-dist build-lv2-sdk package-aap-zip package-prefab

package-libsndfile:
	# ensure that clean-local-dist is called every time
	make clean-local-dist build-libsndfile-deps
	rm -f android-libsndfile-binaries.zip
	zip -r android-libsndfile-binaries.zip dist

package-guitarix:
	# ensure that clean-local-dist is called every time
	make clean-local-dist build-guitarix package-guitarix-zip

package-aap-zip:
	rm -f android-lv2-binaries.zip
	zip -r android-lv2-binaries.zip dist -x '*/doc/*' -x '*/man/*' -x '*/lv2specgen/*'

package-prefab:
	cd prefab && ./build.sh || exit 1 && cd ..

package-guitarix-zip:
	rm -f aap-guitarix-binaries.zip
	zip -r aap-guitarix-binaries.zip dist -x '*/doc/*' -x '*/man/*' -x '*/lv2specgen/*'
