# This Makefile is to build and copy native LV2 dependencies

PWD=$(shell pwd)

ABIS_SIMPLE = x86 x86-64 armv7 arm64
ANDROID_NDK=/home/$(USER)/Android/Sdk/ndk/20.0.5594570/

TOP=`pwd`

all: build copy-outputs

build: build-native

.PHONY:
clean:
	make CERBERO_COMMAND=wipe run-cerbero-command

.PHONY:
prepare:
	cd cerbero && ANDROID_NDK_HOME=$(ANDROID_NDK) ./cerbero-uninstalled -c config/cross-android-x86.cbc bootstrap

.PHONY:
copy-as-dist:
	make DESTINATION=dist copy-dist

.PHONY:
copy-as-ref:
	make DESTINATION=ref copy-dist

.PHONY:
copy-dist:
	mkdir -p ../$(DESTINATION)/x86
	mkdir -p ../$(DESTINATION)/x86_64
	mkdir -p ../$(DESTINATION)/armeabi-v7a
	mkdir -p ../$(DESTINATION)/arm64-v8a
	cp -uR $(TOP)/cerbero/build/dist/android_x86/* ../$(DESTINATION)/x86/
	cp -uR $(TOP)/cerbero/build/dist/android_x86_64/* ../$(DESTINATION)/x86_64/
	cp -uR $(TOP)/cerbero/build/dist/android_armv7/* ../$(DESTINATION)/armeabi-v7a/
	cp -uR $(TOP)/cerbero/build/dist/android_arm64/* ../$(DESTINATION)/arm64-v8a/

.PHONY:
clean-dist:
	rm -rf ../dist/x86 ../dist/x86_64 ../dist/armeabi-v7a ../dist/arm64-v8a

.PHONY:
build-native: build-aap-deps build-guitarix-deps

.PHONY:
build-aap-deps:
	make CERBERO_COMMAND="build libsndfile" run-cerbero-command

.PHONY:
build-guitarix-deps:
	make CERBERO_COMMAND="build libsndfile fftw3 glibmm" run-cerbero-command

.PHONY:
package-native: package-aap-deps package-guitarix-deps

.PHONY:
package-aap-deps:
	make CERBERO_COMMAND="package aap-deps" run-cerbero-command
.PHONY:
package-aap-guitarix-deps:
	make CERBERO_COMMAND="package aap-guitarix-deps" run-cerbero-command

.PHONY:
run-cerbero-command:
	cd cerbero && for abi in $(ABIS_SIMPLE) ; do \
		ANDROID_NDK_HOME=$(ANDROID_NDK) BUILD_ANDROID_ABI=$$abi ./cerbero-uninstalled -c config/cross-android-$$abi.cbc $(CERBERO_COMMAND) ; \
	done

