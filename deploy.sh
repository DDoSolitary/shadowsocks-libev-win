. /etc/profile
set -e
mkdir .ssh
echo $deploy_key | base64 -d > .ssh/id_ed25519
chmod 600 .ssh/id_ed25519
ssh-keyscan github.com > .ssh/known_hosts
git config --global user.name DDoSolitary
git config --global user.email DDoSolitary@gmail.com
git clone git@github.com:DDoSolitary/shadowsocks-libev-win -b $release_branch
cd shadowsocks-libev-win
rm -f *.exe *.dll
cp /cygdrive/c/projects/shadowsocks-libev-win/shadowsocks-libev/output/* .
git add -A
git commit -m "release"
git push
