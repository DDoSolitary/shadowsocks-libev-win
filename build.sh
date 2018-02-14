. /etc/profile

set -e

mkdir .ssh
echo $deploy_key | base64 -d > .ssh/id_ed25519
chmod 600 .ssh/id_ed25519
ssh-keyscan github.com > .ssh/known_hosts

set -x

git config --global user.name DDoSolitary
git config --global user.email DDoSolitary@gmail.com
git config --global core.autocrlf false
git clone https://github.com/shadowsocks/shadowsocks-libev
git clone https://github.com/shadowsocks/simple-obfs
git clone git@github.com:DDoSolitary/shadowsocks-libev-win -b $release_branch

mkdir -p stat
touch stat/installed.db stat/ss-commit stat/obfs-commit
ss_commit="$(git --git-dir=shadowsocks-libev/.git show -s --format=%H)"
obfs_commit="$(git --git-dir=simple-obfs/.git show -s --format=%H)"
if diff /etc/setup/installed.db stat/installed.db && [ "$(cat stat/ss-commit)" == "$ss_commit" ] && [ "$(cat stat/obfs-commit)" == "$obfs_commit" ]; then
	exit 0
fi
cp /etc/setup/installed.db stat/
echo "$ss_commit" > stat/ss-commit
echo "$obfs_commit" > stat/obfs-commit

function build {
	pushd $1
	git submodule update --init
	./autogen.sh
	./configure --disable-documentation
	make
	make DESTDIR="$HOME/dst" install
	popd
}

mkdir dst
build shadowsocks-libev
build simple-obfs
cp /bin/sh.exe dst

cd shadowsocks-libev-win
rm -f *.exe *.dll
cp ../dst/usr/local/bin/* .
cp $(ldd *.exe | awk '$3 ~ /\/usr\/bin\// { print $3 }' | sort | uniq) .
git add -A
git commit \
	-m "Nightly build on $(date +%F) of v$(./ss-local -h | awk 'NR == 2 { print $2 }')." \
	-m "shadowsocks/shadowsocks-libev@$(git --git-dir=../shadowsocks-libev/.git show -s --format=%H)" \
	|| exit 0
git push
