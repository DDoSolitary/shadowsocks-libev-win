. /etc/profile
set -e
git config --global core.autocrlf false
git clone https://github.com/shadowsocks/shadowsocks-libev
cd shadowsocks-libev
git submodule update --init
./autogen.sh
./configure --disable-documentation
make
mkdir dst output
make DESTDIR="$PWD/dst" install
cd output
cp ../dst/usr/local/bin/* .
cp $(ldd *.exe | awk '$3 ~ /\/usr\/bin\// { print $3 }' | sort | uniq) .
