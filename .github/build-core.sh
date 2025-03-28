#!/bin/sh

set -ex

run() {
  printf "\033[0;35m==>\033[0m \033[0;32m%b\n\033[0m" "$*"
  eval "$@"
}

if [ -f cacert.pem ] ; then
    run export SSL_CERT_FILE="$PWD/cacert.pem"
fi

run ./ppkg setup --syspm
run ./ppkg update
run ./ppkg install uppm@0.15.4 --static
run ./ppkg bundle  uppm@0.15.4 .tar.xz

run rm core/AppRun.c core/wrapper-template.c

install -d out/

for f in core/*.c
do
    x="${f#*/}"
    o="out/${x%.c}"
    run cc -flto -Os -std=gnu99 -o "$o" "$f"
    run strip "$o"
done

run export SSL_CERT_FILE="$HOME/.ppkg/core/cacert.pem"

curl -LO https://raw.githubusercontent.com/adobe-fonts/source-code-pro/release/OTF/SourceCodePro-Light.otf
curl -LO https://git.savannah.gnu.org/cgit/config.git/tree/config.sub
curl -LO https://git.savannah.gnu.org/cgit/config.git/tree/config.guess

chmod +x config.sub config.guess

bsdtar vxf uppm*.tar.xz -C out --strip-components=1

mv out/bin/uppm *.otf core/fonts.conf config.sub config.guess out/

rm -rf out/bin/ out/share/ out/.ppkg/

NATIVE_OS_KIND="$(uname -s | tr A-Z a-z)"
NATIVE_OS_ARCH="$(uname -m)"

case $NATIVE_OS_KIND in
    linux)
        DIRNAME="ppkg-core-$1-$NATIVE_OS_KIND-$NATIVE_OS_ARCH"
        ;;
    *)  NATIVE_OS_VERS="$(uname -r)"
        NATIVE_OS_VERS="${NATIVE_OS_VERS%%-*}"
        DIRNAME="ppkg-core-$1-$NATIVE_OS_KIND-$NATIVE_OS_VERS-$NATIVE_OS_ARCH"
esac

mv out "$DIRNAME"

bsdtar cavf "$DIRNAME.tar.xz" "$DIRNAME"
