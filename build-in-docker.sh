docker run -t --rm -v $(pwd):/build-docker bitriseio/android-ndk /bin/bash -ci "cd /build-docker && sudo apt-get update && echo y | sudo apt-get install autogen pkg-config meson nasm && echo y | make prepare && make package"

