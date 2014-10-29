#!/usr/bin/env bash
#

ok() {
    echo -e '\e[32m'$1'\e[m';
}

USR="client"

ok "❯❯❯ Generating Client Config"
openssl genrsa -out /etc/openvpn/$USR\-key.pem 2048 > /dev/null 2>&1
chmod 600 /etc/openvpn/$USR\-key.pem
openssl req -new -key /etc/openvpn/$USR\-key.pem -out /etc/openvpn/$USR\-csr.pem -subj /CN=OpenVPN-$USR/ > /dev/null 2>&1
openssl x509 -req -in /etc/openvpn/$USR\-csr.pem -out /etc/openvpn/$USR\-cert.pem -CA /etc/openvpn/ca.pem -CAkey /etc/openvpn/ca-key.pem -days 36525 > /dev/null 2>&1

cat > /etc/openvpn/$USR.ovpn <<EOF
$USR
nobind
dev tun443
redirect-gateway def1 bypass-dhcp
remote $SERVER_IP 443 tcp
comp-lzo yes

<key>
$(cat /etc/openvpn/$USR\-key.pem)
</key>
<cert>
$(cat /etc/openvpn/$USR\-cert.pem)
</cert>
<ca>
$(cat /etc/openvpn/ca.pem)
</ca>
EOF
