. /etc/profile

set -e

function build {
	pushd $1
	git submodule update --init
	./autogen.sh
	./configure --disable-documentation
	make
	make DESTDIR="$HOME/dst" install
	popd
}

function get-version {
	$1 -h | awk 'NR == 2 { printf $2 }'
}

function get-commit {
	git --git-dir="$1/.git" show -s --format=%H
}

git clone https://github.com/shadowsocks/shadowsocks-libev
git clone https://github.com/shadowsocks/simple-obfs

mkdir dst
build shadowsocks-libev
build simple-obfs

cd dst/usr/local/bin
cp $(ldd *.exe | awk '$3 ~ /\/usr\/bin\// { print $3 }' | sort | uniq) .
tar czf binaries.tar.gz *

curl="curl -sSL -u ddosolitary:$BINTRAY_KEY"
api_prefix=https://api.bintray.com/content/ddosolitary/dev-releases
file_name=shadowsocks-libev-win-$ARCH.tar.gz
$curl -X DELETE $api_prefix/$file_name
$curl -f -T binaries.tar.gz $api_prefix/default/default/$file_name
$curl -f -X POST $api_prefix/default/default/publish
