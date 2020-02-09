# Native library builder for Android

This repository covers various native library builds for Android, namely:

- lv2 (serd, sord, lv2, sratom, lilv, mda-lv2)

## Building for general developers

Run `./build-in-docker.sh` to get a release binary zip on Linux.

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
breakage in gtk due to bogus dependencies on 
