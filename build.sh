. /etc/profile

set -e

mkdir .ssh
echo $deploy_key | base64 -d > .ssh/id_ed25519
chmod 600 .ssh/id_ed25519
ssh-keyscan github.com > .ssh/known_hosts

set -x

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

git config --global user.name DDoSolitary
git config --global user.email DDoSolitary@gmail.com
git config --global core.autocrlf false
git clone https://github.com/shadowsocks/shadowsocks-libev
git clone https://github.com/shadowsocks/simple-obfs
git clone git@github.com:DDoSolitary/shadowsocks-libev-win -b $release_branch

mkdir -p stat
touch stat/installed.db stat/ss-commit stat/obfs-commit stat/script-commit
ss_commit="$(get-commit shadowsocks-libev)"
obfs_commit="$(get-commit simple-obfs)"
if diff /etc/setup/installed.db stat/installed.db && [ "$(cat stat/ss-commit)" == "$ss_commit" ] && [ "$(cat stat/obfs-commit)" == "$obfs_commit" ] && [ "$(cat stat/script-commit)" == "$APPVEYOR_REPO_COMMIT" ]; then
	exit 0
fi
cp /etc/setup/installed.db stat/
echo "$ss_commit" > stat/ss-commit
echo "$obfs_commit" > stat/obfs-commit
echo "$APPVEYOR_REPO_COMMIT" > stat/script-commit

pushd shadowsocks-libev
git apply << EOF
diff --git a/src/plugin.c b/src/plugin.c
--- a/src/plugin.c
+++ b/src/plugin.c
@@ -87,14 +87,6 @@ start_ss_plugin(const char *plugin,
                 const char *local_port,
                 enum plugin_mode mode)
 {
-    char *cmd = NULL;
-
-    size_t plugin_len = strlen(plugin);
-    size_t cmd_len    = plugin_len + CMD_RESRV_LEN;
-    cmd = ss_malloc(cmd_len);
-
-    snprintf(cmd, cmd_len, "exec %s", plugin);
-
     cork_env_add(env, "SS_REMOTE_HOST", remote_host);
     cork_env_add(env, "SS_REMOTE_PORT", remote_port);

@@ -104,7 +96,7 @@ start_ss_plugin(const char *plugin,
     if (plugin_opts != NULL)
         cork_env_add(env, "SS_PLUGIN_OPTIONS", plugin_opts);

-    exec = cork_exec_new_with_params("sh", "-c", cmd, NULL);
+    exec = cork_exec_new(plugin);

     cork_exec_set_env(exec, env);

@@ -112,8 +104,6 @@ start_ss_plugin(const char *plugin,

     int err = cork_subprocess_start(sub);

-    ss_free(cmd);
-
     return err;
 }
EOF
popd

mkdir dst
build shadowsocks-libev
build simple-obfs

cd shadowsocks-libev-win
rm -f *.exe *.dll
cp ../dst/usr/local/bin/* .
cp $(ldd *.exe | awk '$3 ~ /\/usr\/bin\// { print $3 }' | sort | uniq) .
git add -A

git commit \
	-m "Built on $(date +%F) for shadowsocks-libev v$(get-version ./ss-local) and simple-obfs v$(get-version ./obfs-local)." \
	-m "shadowsocks/shadowsocks-libev@$ss_commit shadowsocks/simple-obfs@$obfs_commit" \
	|| exit 0
git push
