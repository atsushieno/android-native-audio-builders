# Native library builder for Android

This repository covers various native library builds for Android, namely:

- lv2 (serd, sord, lv2, sratom, lilv, mda-lv2)
- eigen (well, not really; it's just copying headers)
- guitarix

... as well as dependencies:

- libogg, libvorbis, flac, libsndfile, fftw3
- libffi, glib, mm-common, libsigc++, glibmm

To build those dependencies, we make full use of 
[GStreamer/Cerbero](https://github.com/GStreamer/cerbero) build
system - actually a fork of it - which provides comprehensive automated
builds for all Android ABI.
Unlike [Microsoft/vcpkg](https://github.com/microsoft/vcpkg/) packages
are up to date well and tailored well for Linux, and unlike AOSP 
[ndkports](https://android.googlesource.com/platform/tools/ndkports/)
it can resolve complicated dependencies in many build systems
(for example, basic Autotools deps).

Although note that our fork is rebased on Android-28 which contains
iconv API in bionic libc.

We needed 28 to include certain pthread API for `zita-*`, but now that
they are removed we may bring back the default API level by cerbero
(not sure, it is more consistent to not have libiconv for every ABI).

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

## Adding packages

You would often like to build more LV2 plugins with this script, and
sometimes it's easier to just reuse the build scripts in this repo to
resolve complicated set of dependencies like what Guitarix has (glibmm,
libsndfile, fftw3).

The Makefile script is already quite complicated, but `aap-guitarix` build
can be still regarded as a reference model to split LV2 core builds from
the app build itself. The resulting build outputs can be packaged just by
processing `dist` directory.

### Tweak build settings

Ubuntu 20.04 is the expected build machine. We have a CI build based on that.

We do have `build-in-docker.sh` but it is totally untested nowadays. GitHub
Actions workflows provides more precise setup. But note that it is based on
their server settings, which already has some software setup.

On some Ubuntu desktop later than 18.04, libpng12 might cause serious
package inconsistency and would result in inability to update anything.
Try this to avoid such a problem: https://www.linuxuprising.com/2018/05/fix-libpng12-0-missing-in-ubuntu-1804.html

On some Linux desktop (maybe after Ubuntu 18.04) lv2 sample plugins fail
to build for unknown reason.
In `Makefile` there is a line that builds lv2 with some options.
Add `--no-plugins` to avoid such build failures.

