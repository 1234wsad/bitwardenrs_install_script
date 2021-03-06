####     Thanks to wh1te909 who I stole (or got inspiration) alot of this script from (first script I have ever written) 
####     and https://pieterhollander.nl/post/bitwarden/ which I followed the steps and converted them to a script

#check if running on ubuntu 20.04
UBU20=$(grep 20.04 "/etc/"*"release")
if ! [[ $UBU20 ]]; then
  echo -ne "\033[0;31mThis script will only work on Ubuntu 20.04\e[0m\n"
  exit 1
fi

#Ensure not running as root
if [ $EUID -eq 0 ]; then
  echo -ne "\033[0;31mDo NOT run this script as root. Exiting.\e[0m\n"
  exit 1
fi

#Username
echo -ne "Enter your created username if you havent done this please do it now, use ctrl+c to cancel this script and do it${NC}: "
read username

#Clean up old folders
rm -rf ~/bitwarden_rs ~/web

#Upgrade Rust
curl https://sh.rustup.rs -sSf | sh
source $HOME/.cargo/env

#Download newest versions of Bitwarden RS and compile
git clone https://github.com/dani-garcia/bitwarden_rs.git
cd bitwarden_rs/
git checkout
cargo build --features sqlite --release
cd ..

#Clone and checkout repository for Bitwarden web and patch
git clone https://github.com/bitwarden/web.git
cd web
git checkout
wget https://raw.githubusercontent.com/dani-garcia/bw_web_builds/master/patches/\$(git tag --sort=v:refname | tail -n1).patch
git apply \$(git tag --sort=v:refname | tail -n1).patch

#Build Web
npm run sub:init
npm install
npm audit fix
npm run dist
cd ..

#Apply Updates and restart Bitwarden_RS
sudo systemctl stop bitwarden.service
sudo cp -r ~/bitwarden_rs/target/release/bitwarden_rs /opt/bitwardenrs
sudo rm -rf /opt/bitwardenrs/web-vault
sudo mv ~/web/build /opt/bitwardenrs/web-vault
sudo chown -R ${username}:${username} /opt/bitwardenrs
sudo systemctl start bitwarden.service
