. /etc/profile

set -e

export PATH=/usr/bin

git clone https://github.com/shadowsocks/shadowsocks-libev
cd shadowsocks-libev
git submodule update --init

cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWITH_STATIC=OFF -DWITH_SS_REDIR=OFF
make

mkdir dst
cp shared/bin/* lib/libshadowsocks-libev.dll.a  bin/* dst
cd dst
cp $(ldd *.exe *.dll | awk '$3 ~ /\/usr\/bin\// { print $3 }' | sort | uniq) .
tar czf binaries.tar.gz *

curl="curl -sSL -u ddosolitary:$BINTRAY_KEY"
api_prefix=https://api.bintray.com/content/ddosolitary/dev-releases
file_name=shadowsocks-libev-win-$ARCH.tar.gz
$curl -X DELETE $api_prefix/$file_name
$curl -f -T binaries.tar.gz $api_prefix/default/default/$file_name
$curl -f -X POST $api_prefix/default/default/publish
