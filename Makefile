# This Makefile is to build and copy native LV2 dependencies

PWD=$(shell pwd)

ANDROID_NDK=/home/$(USER)/Android/Sdk/ndk/20.0.5594570/
LLVM_TOOLCHAIN=$(ANDROID_NDK)/toolchains/llvm/prebuilt/linux-x86_64
ANDROID_TOOLCHAIN=$(ANDROID_NDK)/toolchains/$(ABI_COMPLEX)-4.9/prebuilt/linux-x86_64

# for build-single
PKG_CONFIG_PATH=$(PWD)/dist/$(ABI_FORMAL)/lib/pkgconfig:$(PWD)/cerbero-artifacts/outputs/$(ABI_FORMAL)/lib/pkgconfig
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
package: build do-package

do-package:
	rm -f android-lv2-binaries.zip
	zip -r android-lv2-binaries.zip dist -x '*/doc/*' -x '*/man/*' -x '*/lv2specgen/*'

.PHONY:
build: download-ndk build-cerbero-deps build-lv2-stuff

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
	make MODULE=lv2 MODULE_MAJOR=0 MODULE_OPTIONS="--copy-headers --no-plugins" build-single-no-soname-opt
	make MODULE=sratom MODULE_MAJOR=0 MODULE_VER=0.6.4 build-single
	make MODULE=lilv MODULE_MAJOR=0 MODULE_VER=0.24.7 MODULE_OPTIONS="--no-utils" build-single
	make MODULE=mda-lv2 MODULE_MAJOR=0 build-single-no-soname-opt

.PHONY:
clean-single-abi:
	make MODULE=mda-lv2 clean-single
	make MODULE=lilv clean-single
	make MODULE=lv2 clean-single
	make MODULE=sratom clean-single
	make MODULE=sord clean-single
	make MODULE=serd clean-single

.PHONY:
build-single:
	make LDFLAGS="-Wl,-soname,lib$(MODULE)-$(MODULE_MAJOR).so" build-single-no-soname-opt
	mv dist/$(ABI_FORMAL)/lib/lib$(MODULE)-$(MODULE_MAJOR).so.$(MODULE_VER) dist/$(ABI_FORMAL)/lib/lib$(MODULE)-$(MODULE_MAJOR).so
	rm dist/$(ABI_FORMAL)/lib/lib$(MODULE)-$(MODULE_MAJOR).so.0

.PHONY:
build-single-no-soname-opt:
	echo "Building $(MODULE) for $(ABI_FORMAL) ($(ABI_COMPLEX)) ..."
	mkdir -p build/$(ABI_FORMAL)/$(MODULE)
	cp -R $(MODULE)/* build/$(ABI_FORMAL)/$(MODULE)/
	cd build/$(ABI_FORMAL)/$(MODULE) && \
	PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" \
	CC="$(CC)" \
	CXX="$(CXX)" \
	LD="$(LD)" \
	CFLAGS="$(CFLAGS)" \
	LDFLAGS="-landroid $(LDFLAGS)" \
	./waf -d $(MODULE_OPTIONS) --prefix=../../../dist/$(ABI_FORMAL) configure && \
	echo "autowaf has a horrible issue that it moves away all those required external CFLAGS and it's used everywhere, meaning that making changes to it will mess the future builds. As a workaround, we hack those configure results" && \
	sed -i -e "s/CFLAGS = \[/CFLAGS = \[$(CFLAGS), /" build/c4che/_cache.py && \
	./waf -d $(MODULE_OPTIONS) --prefix=../../../dist/$(ABI_FORMAL) build install && \
	cd ../../.. || exit 1

.PHONY:
clean-single:
	# It looks too verbose steps, but ensures that we don't accidentaly remove unexpected directory (e.g. what happens if ABI_FORMAL and MODULE are empty?)
	cd build/$(ABI_FORMAL)/$(MODULE) && ./waf clean && cd ../../.. && rm -rf build/$(ABI_FORMAL)/$(MODULE)

