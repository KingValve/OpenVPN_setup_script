#!/usr/bin/env bash
#

USR="client"

# Functions
ok() {
    echo -e '\e[32m'$1'\e[m';
}

die() {
    echo -e '\e[1;31m'$1'\e[m'; exit 1;
}

# Sanity check
if [[ $(id -g) != "0" ]] ; then
    die "❯❯❯ Script must be run as root."
fi

if [[  ! -e /dev/net/tun ]] ; then
    die "❯❯❯ TUN/TAP device is not available."
fi

# IP Address
SERVER_IP=$(curl ipv4.icanhazip.com)
if [[ -z "${SERVER_IP}" ]]; then
    SERVER_IP=$(ip a | awk -F"[ /]+" '/global/ && !/127.0/ {print $3; exit}')
fi

# Generate Client Config
ok "❯❯❯ Generating $USR Config"
openssl genrsa -out /etc/openvpn/$USR\-key.pem 2048 > /dev/null 2>&1
chmod 600 /etc/openvpn/$USR\-key.pem
openssl req -new -key /etc/openvpn/${USR}-key.pem -out /etc/openvpn/${USR}-csr.pem -subj /CN=OpenVPN-${USR} > /dev/null 2>&1
openssl x509 -req -in /etc/openvpn/${USR}-csr.pem -out /etc/openvpn/${USR}-cert.pem -CA /etc/openvpn/ca.pem -CAkey /etc/openvpn/ca-key.pem -days 36525 > /dev/null 2>&1

cat > /etc/openvpn/$USR.ovpn <<EOF
${USR}
nobind
dev tun
redirect-gateway def1 bypass-dhcp
remote $SERVER_IP 443 tcp
comp-lzo yes

<key>
$(cat /etc/openvpn/${USR}-key.pem)
</key>
<cert>
$(cat /etc/openvpn/${USR}-cert.pem)
</cert>
<ca>
$(cat /etc/openvpn/ca.pem)
</ca>
EOF

# Restart Service
ok "❯❯❯ service openvpn restart"
service openvpn restart > /dev/null 2>&1
ok "❯❯❯ Your $USR config is available at /etc/openvpn/${USR}.ovpn"
ok "❯❯❯ All done!"
