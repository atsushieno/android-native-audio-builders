# Native library builder for Android

This repository covers various native library builds for Android, namely:

- lv2 (serd, sord, lv2, sratom, lilv, mda-lv2)
- eigen (well, not really; it's just copying headers)
- guitarix

... as well as dependencies:

- libogg, libvorbis, flac, libsndfile
- fftw3, zita-convolver, zita-resampler
- libffi, glib, mm-common, libsigc++, glibmm

although note that they are based on Android-28 which contains iconv API
in bionic libc. We needed 28 to include certain pthread API IIRC for `zita-*`.
We may remove `zita-*` stuff mostly because we don't need them anymore
(they are part of guitarix sources, and guitarix is the only bit that
needs them).

## Building for general developers

Run `./build-in-docker.sh` to get a release binary zip on Linux.

## Notes on pkg-config usage

The resulting binary, especially those on github release page, has `*.pc` files (for pkg-config) has path specification on the build machine and therefore they won't work as is on your machine.

You are supposed to rewrite those path specifications (like `prefix`, but not limited to this) with your local path to the specific Android ABI directory in the extracted directory of the (downloaded) archive. For example...

```
#!/bin/bash

PWD=`pwd`
PWDESC=${PWD//\//\\\/}

echo $PWDESC

for f in `find dependencies/dist/*/lib/pkgconfig -name *.pc` ; do
	sed -e "s/\/home\/runner\/work\/android-native-audio-builders\/android-native-audio-builders\/cerbero-artifacts\/cerbero\/build/$PWDESC\/dependencies/g" $f > $f.1;
	sed -e "s/\/home\/runner\/work\/android-native-audio-builders\/android-native-audio-builders/$PWDESC\/dependencies/g" $f.1 > $f.2 ;
done
```

## Hacking

Since `./build-in-docker.sh` involves package installation, NDK downloads, building
deps and so on, it is not very efficient when you just want to make changes.
Just run `make prepare && make`, which is much faster (but you would need some
reproducible Linux desktop).

On some Ubuntu desktop later than 18.04, libpng12 might cause serious package
inconsistency and would result in inability to update anything. Try this to avoid
such a problem: https://www.linuxuprising.com/2018/05/fix-libpng12-0-missing-in-ubuntu-1804.html

On some Linux desktop (maybe after Ubuntu 18.04) lv2 sample plugins fail to build
for unknown reason. In `Makefile` there is a line that builds lv2 with some options.
Add `--no-plugins` to avoid such build failures.

