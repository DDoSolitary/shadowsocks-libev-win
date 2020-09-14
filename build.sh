if [[ "$TOOLCHAIN" == 'cygwin' ]]; then
	export PATH=/usr/bin
fi

if [[ "$TOOLCHAIN" == 'mingw' ]]; then
	git clone https://github.com/shadowsocks/libev -b mingw
	cd libev
	./autogen.sh
	./configure
	make LDFLAGS='-no-undefined -lws2_32'
	make install
	cd ..
fi

git clone https://github.com/shadowsocks/shadowsocks-libev
cd shadowsocks-libev
git submodule update --init
cd build
if [[ "$TOOLCHAIN" == 'cygwin' ]]; then
	cmake_args='-DWITH_STATIC=OFF -DWITH_SS_REDIR=OFF'
elif [[ "$TOOLCHAIN" == 'mingw' ]]; then
	cmake_args='-G "MSYS Makefiles" -DWITH_DOC_MAN=OFF -DWITH_DOC_HTML=OFF'
fi
eval cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo $cmake_args
make

mkdir dst
cp shared/bin/* lib/libshadowsocks-libev.dll.a  bin/*.dll ../src/shadowsocks.h ../LICENSE dst
cd dst
if [[ "$TOOLCHAIN" == 'cygwin' ]]; then
	bin_prefix='\/usr\/bin\/'
	deps="$(ldd *.exe *.dll)"
elif [[ "$TOOLCHAIN" == 'mingw' ]]; then
	bin_prefix='\'"$MINGW_PREFIX"'\/bin\/'
	deps="$(for i in *.exe *.dll; do ntldd $i; done | sed 's|\\|/|g')"
fi
deps="$(echo "$deps" | awk '$3 ~ /'"$bin_prefix"'/ { print $3 }' | sort | uniq)"
cp $deps .
if [[ "$TOOLCHAIN" == 'mingw' ]]; then
	script='CREATE libshadowsocks-libev.a'
	for i in $(echo "$deps" | sed -E 's/(-|\.).*/.a/;s|/bin/|/lib/|'); do
		if [[ -f "$i" ]]; then
			script="$(printf "$script\nADDLIB $i")"
	       	fi
	done
	for i in $(find ../lib -type f ! -name '*.dll.a'); do
		script="$(printf "$script\nADDLIB $i")"
	done
	script="$(printf "$script\nSAVE\nEND")"
	echo "$script" | ar -M
fi

tar czf binaries.tar.gz *

if [ "$GITHUB_REF" = refs/heads/master ]; then
	mkdir -p ~/.ssh
	echo $DEPLOYKEY | base64 -d > ~/.ssh/id_ed25519
	chmod 600 ~/.ssh/id_ed25519
	ssh-keyscan web.sourceforge.net > ~/.ssh/known_hosts
	scp \
		binaries.tar.gz \
		ddosolitary@web.sourceforge.net:/home/project-web/ddosolitary-builds/htdocs/shadowsocks-libev-win/shadowsocks-libev-$TOOLCHAIN-$ARCH.tar.gz
fi
