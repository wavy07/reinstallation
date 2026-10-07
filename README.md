# reinstallation
reinstall your vps os in terminal🟢

INSTALLATION🦜🐐
```bash

# on the server
sudo rm -f /etc/resolv.conf

sudo tee /etc/resolv.conf >/dev/null <<'EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 9.9.9.9
EOF &&
apt update &&
apt install -y curl
&&
curl -fsSL https://raw.githubusercontent.com/wavy07/reinstallation/main/reinstall.sh -o reinstall.sh   
bash reinstall.sh
