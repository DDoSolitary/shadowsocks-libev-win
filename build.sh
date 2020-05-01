. /etc/profile

set -e

git clone https://github.com/shadowsocks/shadowsocks-libev
cd shadowsocks-libev
git submodule update --init

./autogen.sh
./configure --disable-documentation
make

mkdir dst
make DESTDIR=dst install
cd dst/usr/local/bin
cp $(ldd *.exe | awk '$3 ~ /\/usr\/bin\// { print $3 }' | sort | uniq) .
tar czf binaries.tar.gz *

curl="curl -sSL -u ddosolitary:$BINTRAY_KEY"
api_prefix=https://api.bintray.com/content/ddosolitary/dev-releases
file_name=shadowsocks-libev-win-$ARCH.tar.gz
$curl -X DELETE $api_prefix/$file_name
$curl -f -T binaries.tar.gz $api_prefix/default/default/$file_name
$curl -f -X POST $api_prefix/default/default/publish
