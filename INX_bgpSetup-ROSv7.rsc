# IPT and NAP Sample setup Script
# Please email david@mikro.ninja with any questions

# Define AS Number by replacing 65530 below with your own ASN
:global asn 65530

# Define BGP Instance Router ID
# This should be a public or private IP on your router (usually loopback)
:global rid 0.1.2.3

# Specify if IPv6 should also be setup
# Change to no if you do not want IPv6 rules added
# Change ipv6add value to your IPv6 network range
:global addipv6 yes
:global ipv6add 2c0f:0000::/32

# Specify if Primary IPT Provider should also be setup
# Change to yes if you want IPT Primary to be added
:global addipt yes

# If you have an IPT provider modify below
# Set my_ipt_provider to the name of your IPT - do not use spaces
# Set 0.2.0.0 and 2c0f:1000::/32 to the IPT Provider BGP peer IP addresses as required
# Set iptpriasn to your IPT AS Number
:global iptpriname my_ipt_provider
:global iptpriaddressv4 0.2.0.0
:global iptpriaddressv6 2c0f:1000::1234
:global iptpriasn 65532

# Define IPv4 network ranges to advertise
# You need to add all networks and subnetworks you require
# This needs to match the scope setting below as defined by v4preflen property
# e.g. to add 100.64.10.0/22 with prefix length 22-24 you would add
# address=100.64.0.0/22
# address=100.64.0.0/23
# address=100.64.2.0/23
# address=100.64.0.0/24
# address=100.64.1.0/24
# address=100.64.2.0/24
# address=100.64.3.0/24

/
/ip firewall address-list add list=bgp-networks-v4 address=0.1.0.0/22
#/ip firewall address-list add list=bgp-networks-v4 address=0.1.0.0/23
#/ip firewall address-list add list=bgp-networks-v4 address=0.1.2.0/23
#/ip firewall address-list add list=bgp-networks-v4 address=0.2.0.0/22

# Define the scope of network you want to advertise
# Example "22" to advertise only your /22 aggregate
# Example "22-24" to advertise all /22 /23 and /24 network ranges
:global v4preflen 22-23

# Define outgoing priority as per location
# Currently this prefers NAP Johannesburg
# If you are in Cape Town switch the CT and JB priorities as required
# Primary IPT default route
:global iptpridef 110
# Secondary IPT default route
:global iptsecdef 100
# Primary IPT routes
:global iptprinet 130
# Secondary IPT Routes
:global iptsecnet 120
# NAP Cape Town route servers
:global ctprio 300
# NAP Johannesburg route servers
:global jbprio 350
# NAP Cape Town Bi Lateral Peers
:global ctblpprio 400
# NAP Johannesburg Bi Lateral Peers
:global jbblpprio 450

# Uncomment the 2 lines below if you have not yet defined a loopback
# /interface/bridge/add name=bgp_loopback protocol-mode=none
# /ip/address/add interface=bgp_loopback address=$rid

# ***********************************************
# *                                             *
# *  DO NOT CHANGE ANYTHING BELOW THIS COMMENT  *
# *                                             *
# ***********************************************

# Enable IPv6 and add IPv6 Address List
if ($addipv6=yes) do={
/ipv6 settings set disable-ipv6=no}
/ipv6 firewall address-list add list=bgp-networks-v6 address=$ipv6add
}

# Add blackhole routes for covering ranges
{
:foreach k in=[/ip/firewall/address-list find where list=bgp-networks-v4] do={
:local tmpBgpNet [/ip/firewall/address-list get $k address];
/ip/route/add dst-address=$tmpBgpNet blackhole};
:foreach j in=[/ipv6/firewall/address-list find where list=bgp-networks-v6] do={
:local tmpBgpNet6 [/ipv6/firewall/address-list get $j address];
/ipv6/route/add dst-address=$tmpBgpNet6 blackhole};
}

# Add NAP RPKI Servers

/routing rpki add address=196.60.70.2 disabled=no group=NAPCT port=3323 
/routing rpki add address=196.60.70.3 disabled=no group=NAPCT port=3323 
/routing rpki add address=196.60.9.2 disabled=no group=NAPJB port=3323 
/routing rpki add address=196.60.9.3 disabled=no group=NAPJB port=3323 
/

# Add common templates for establishing BGP peers

# Setup BGP Templates for IPT

/routing/bgp/template add address-families=ip as=$asn disabled=no input.filter=ipt-in-primary-v4 name=( "template-ipt-pri-v4-" . $iptpriname ) output.filter-chain=ipt-out-primary-v4 .network=bgp-networks-v4 router-id=$rid routing-table=main
if ($addipv6=yes) do={/routing/bgp/template add address-families=ipv6 as=$asn disabled=no input.filter=ipt-in-primary-v6 name=( "template-ipt-pri-v6-" . $iptpriname ) output.filter-chain=ipt-out-primary-v6 .network=bgp-networks-v6 router-id=$rid routing-table=main}

# Setup BGP Templates for INX and BLP

/routing/bgp/template add address-families=ip as=$asn disabled=no input.filter=blp-in-v4-jb name=template-blp-v4-jb output.filter-chain=nap-out-v4 .network=bgp-networks-v4 router-id=$rid routing-table=main
if ($addipv6=yes) do={/routing/bgp/template add address-families=ipv6 as=$asn disabled=no input.filter=blp-in-v6-jb name=template-blp-v6-jb output.filter-chain=nap-out-v6 .network=bgp-networks-v4 router-id=$rid routing-table=main}
/routing/bgp/template add address-families=ip as=$asn disabled=no input.filter=blp-in-v4-ct name=template-blp-v4-ct output.filter-chain=nap-out-v4 .network=bgp-networks-v4 router-id=$rid routing-table=main
if ($addipv6=yes) do={/routing/bgp/template add address-families=ipv6 as=$asn disabled=no input.filter=blp-in-v6-ct name=template-blp-v6-ct output.filter-chain=nap-out-v6 .network=bgp-networks-v4 router-id=$rid routing-table=main}
/routing/bgp/template add address-families=ip as=$asn disabled=no input.filter=nap-in-v4-jb name=template-nap-v4-jb output.filter-chain=nap-out-v4 .network=bgp-networks-v4 router-id=$rid routing-table=main
/routing/bgp/template add address-families=ip as=$asn disabled=no input.filter=nap-in-v4-ct name=template-nap-v4-ct output.filter-chain=nap-out-v4 .network=bgp-networks-v4 router-id=$rid routing-table=main
if ($addipv6=yes) do={/routing/bgp/template add address-families=ipv6 as=$asn disabled=no input.filter=nap-in-v6-jb name=template-nap-v6-jb output.filter-chain=nap-out-v6 .network=bgp-networks-v4 router-id=$rid routing-table=main}
if ($addipv6=yes) do={/routing/bgp/template add address-families=ipv6 as=$asn disabled=no input.filter=nap-in-v6-jb name=template-nap-v6-ct output.filter-chain=nap-out-v6 .network=bgp-networks-v4 router-id=$rid routing-table=main}

# This will setup routing filters to accept/deny various routes
# Please read through carefully before deploying

# enable to accept default route on IPT Primary and Backup

/routing filter rule add chain=ipt-in-primary-v4 comment="Accept primary default route" disabled=no rule="if (dst == 0.0.0.0/0) { set bgp-local-pref $iptpridef; accept; }"
/routing filter rule add chain=ipt-in-backup-v4 comment="Accept backup default route" disabled=yes rule="if (dst == 0.0.0.0/0) { set bgp-local-pref $iptsecdef; accept; }"

# enable to only accept IPT default route and nothing else

/routing filter rule add chain=ipt-in-primary-v4 comment="Only accept default route from IPT" disabled=no rule="reject;"
/routing filter rule add chain=ipt-in-backup-v4 comment="Only accept default route from IPT" disabled=yes rule="reject;"

# These rules will discard common bogons and default route, as well as own range, but accept any other routes from IPT
# Be aware if the IPT provider sends a full routing table this fill up your routing table rapidly
# These are needed if your IPT provides a default as well as some local routes not reachable via the IXP

/routing filter rule add chain=ipt-in-primary-v4 comment="Discard default route and private ranges" disabled=no rule="jump rfc5735;"
/routing filter rule add chain=ipt-in-primary-v4 comment="Do not accept own prefix" disabled=no rule="if (dst in bgp-networks-v4 && dst-len >= 32) { reject; }"
/routing filter rule add chain=ipt-in-primary-v4 comment="Accept other IPT Primary routes" disabled=no rule="set bgp-local-pref $iptprinet; accept"
/routing filter rule add chain=ipt-in-backup-v4 comment="Discard default route and private ranges" disabled=no rule="jump rfc5735;"
/routing filter rule add chain=ipt-in-backup-v4 comment="Do not accept own prefix" disabled=no rule="if (dst in bgp-networks-v4 && dst-len >= 32) { reject; }"
/routing filter rule add chain=ipt-in-backup-v4 comment="Accept other IPT Primary routes" disabled=no rule="set bgp-local-pref $iptsecnet; accept"

# Define route advertisements


/routing filter rule add chain=ipt-out-primary-v4 comment="Advertise Primary IPT AS-Path-Length=1" disabled=no rule="if (dst in bgp-networks-v4 && dst-len in $v4preflen) { accept; }"
/routing filter rule add chain=ipt-out-primary-v4 comment="Discard other advertisements" disabled=no rule="reject;"
/routing filter rule add chain=ipt-out-backup-v4 comment="Advertise Primary IPT AS-Path-Length=3" disabled=no rule="if (dst in bgp-networks-v4 && dst-len in $v4preflen) { set bgp-path-prepend 3; accept; }"
/routing filter rule add chain=ipt-out-backup-v4 comment="Discard other advertisements" disabled=no rule="reject;"

# Define accept Filters for NAP and BLP


/routing filter rule add chain=nap-in-v4-jb comment="Discard default route and private ranges" disabled=no rule="jump rfc5735;"
/routing filter rule add chain=nap-in-v4-jb comment="Do not accept own prefix" disabled=no rule="if (dst in bgp-networks-v4 && dst-len >= 32) { reject; }"
/routing filter rule add chain=nap-in-v4-jb comment="Set localpref" disabled=no rule="set bgp-local-pref $jbprio; accept"
/routing filter rule add chain=nap-in-v4-ct comment="Discard default route and private ranges" disabled=no rule="jump rfc5735;"
/routing filter rule add chain=nap-in-v4-ct comment="Do not accept own prefix" disabled=no rule="if (dst in bgp-networks-v4 && dst-len >= 32) { reject; }"
/routing filter rule add chain=nap-in-v4-ct comment="Set localpref" disabled=no rule="set bgp-local-pref $ctprio; accept"
/routing filter rule add chain=nap-out-v4 comment="Advertise own range" disabled=no rule="if (dst in bgp-networks-v4 && dst-len in $v4preflen) { accept; }"
/routing filter rule add chain=nap-out-v4 comment="Discard other advertisements" disabled=no rule="reject;"
/routing filter rule add chain=blp-in-v4-jb comment="Discard default route and private ranges" disabled=no rule="jump rfc5735;"
/routing filter rule add chain=blp-in-v4-jb comment="Do not accept own prefix" disabled=no rule="if (dst in bgp-networks-v4 && dst-len >= 32) { reject; }"
/routing filter rule add chain=blp-in-v4-jb comment="Set localpref" disabled=no rule="set bgp-local-pref $jbblpprio; accept"
/routing filter rule add chain=blp-in-v4-ct comment="Discard default route and private ranges" disabled=no rule="jump rfc5735;"
/routing filter rule add chain=blp-in-v4-ct comment="Do not accept own prefix" disabled=no rule="if (dst in bgp-networks-v4 && dst-len >= 32) { reject; }"
/routing filter rule add chain=blp-in-v4-ct comment="Set localpref" disabled=no rule="set bgp-local-pref $ctblpprio; accept"
/routing filter rule add chain=blp-out-v4 comment="Advertise own range" disabled=no rule="if (dst in bgp-networks-v4 && dst-len in $v4preflen) { accept; }"
/routing filter rule add chain=blp-out-v4 comment="Discard other advertisements" disabled=no rule="reject;"

# Define Bogon / Martian / Private range filters


/routing filter rule add chain=rfc5735 comment="default route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=rfc5735 comment="Prefix >24" disabled=no rule="if (dst-len in 25-32) { reject; }"
/routing filter rule add chain=rfc5735 comment="This network" disabled=no rule="if (dst in 0.0.0.0/8 && dst-len in 8-32) { reject; }"
/routing filter rule add chain=rfc5735 comment=Loopback disabled=no rule="if (dst in 127.0.0.0/8 && dst-len in 8-32) { reject; }"
/routing filter rule add chain=rfc5735 comment=Private disabled=no rule="if (dst in 10.0.0.0/8 && dst-len in 8-32) { reject; }"
/routing filter rule add chain=rfc5735 comment="CG Nat" disabled=no rule="if (dst in 100.64.0.0/10 && dst-len in 10-32) { reject; }"
/routing filter rule add chain=rfc5735 comment=Private disabled=no rule="if (dst in 172.16.0.0/12 && dst-len in 12-32) { reject; }"
/routing filter rule add chain=rfc5735 comment=Private disabled=no rule="if (dst in 192.168.0.0/16 && dst-len in 16-32) { reject; }"
/routing filter rule add chain=rfc5735 comment=Private disabled=no rule="if (dst in 169.254.0.0/16 && dst-len in 16-32) { reject; }"
/routing filter rule add chain=rfc5735 comment=ietf disabled=no rule="if (dst in 192.0.0.0/24 && dst-len in 24-32) { reject; }"
/routing filter rule add chain=rfc5735 comment=ietf disabled=no rule="if (dst in 192.0.2.0/24 && dst-len in 24-32) { reject; }"
/routing filter rule add chain=rfc5735 comment=reserved disabled=no rule="if (dst in 192.88.99.0/24 && dst-len in 24-32) { reject; }"
/routing filter rule add chain=rfc5735 comment="benchmark testing" disabled=no rule="if (dst in 198.18.0.0/15 && dst-len in 15-32) { reject; }"
/routing filter rule add chain=rfc5735 comment="benchmark testing" disabled=no rule="if (dst in 198.51.100.0/24 && dst-len in 24-32) { reject; }"
/routing filter rule add chain=rfc5735 comment="benchmark testing" disabled=no rule="if (dst in 203.0.113.0/24 && dst-len in 24-32) { reject; }"
/routing filter rule add chain=rfc5735 comment=Multicast disabled=no rule="if (dst in 224.0.0.0/3 && dst-len in 3-32) { reject; }"
/routing filter rule add chain=rfc5735 comment="Return from chain" disabled=no rule="return;"

if ($addipv6=yes) do {
/routing filter rule add chain=ipt-in-primary-v6 comment="Accept primary default route" disabled=no rule="if (dst == ::/0) { set bgp-local-pref $iptpridef; accept; }"
/routing filter rule add chain=ipt-in-backup-v6 comment="Accept backup default route" disabled=yes rule="if (dst == ::/0) { set bgp-local-pref $iptsecdef; accept; }"
/routing filter rule add chain=ipt-in-primary-v6 comment="Only accept default route from IPT" disabled=no rule="reject;"
/routing filter rule add chain=ipt-in-backup-v6 comment="Only accept default route from IPT" disabled=yes rule="reject;"
/routing filter rule add chain=ipt-in-primary-v6 comment="Discard default route and private ranges" disabled=no rule="jump ipv6martian;"
/routing filter rule add chain=ipt-in-primary-v6 comment="Do not accept own prefix" disabled=no rule="if (dst in bgp-networks-v6 && dst-len >= 128) { reject; }"
/routing filter rule add chain=ipt-in-primary-v6 comment="Accept other IPT Primary routes" disabled=no rule="set bgp-local-pref $iptprinet; accept"
/routing filter rule add chain=ipt-in-backup-v6 comment="Discard default route and private ranges" disabled=yes rule="jump ipv6martian;"
/routing filter rule add chain=ipt-in-backup-v6 comment="Do not accept own prefix" disabled=yes rule="if (dst in bgp-networks-v6 && dst-len >= 128) { reject; }"
/routing filter rule add chain=ipt-in-backup-v6 comment="Accept other IPT Primary routes" disabled=yes rule="set bgp-local-pref $iptsecnet; accept"
/routing filter rule add chain=ipt-out-primary-v6 comment="Advertise Primary IPT AS-Path-Length=1" disabled=no rule="if (dst in bgp-networks-v6) { accept; }"
/routing filter rule add chain=ipt-out-primary-v6 comment="Discard other advertisements" disabled=no rule="reject;"
/routing filter rule add chain=ipt-out-backup-v6 comment="Advertise Primary IPT AS-Path-Length=3" disabled=no rule="if (dst in bgp-networks-v6) { set bgp-path-prepend 3; accept; }"
/routing filter rule add chain=ipt-out-backup-v6 comment="Discard other advertisements" disabled=no rule="reject;"
/routing filter rule add chain=nap-in-v6-jb comment="Discard default route and private ranges" disabled=no rule="jump ipv6martian;"
/routing filter rule add chain=nap-in-v6-jb comment="Do not accept own prefix" disabled=no rule="if (dst in bgp-networks-v6 && dst-len in 32-128) { reject; }"
/routing filter rule add chain=nap-in-v6-jb comment="Set localpref" disabled=no rule="set bgp-local-pref $jbprio; accept"
/routing filter rule add chain=nap-in-v6-ct comment="Discard default route and private ranges" disabled=no rule="jump ipv6martian;"
/routing filter rule add chain=nap-in-v6-ct comment="Do not accept own prefix" disabled=no rule="if (dst in bgp-networks-v6 && dst-len in 32-128) { reject; }"
/routing filter rule add chain=nap-in-v6-ct comment="Set localpref" disabled=no rule="set bgp-local-pref $ctprio; accept"
/routing filter rule add chain=nap-out-v6 comment="Advertise own range" disabled=no rule="if (dst in bgp-networks-v6 && dst-len == 32) { accept; }"
/routing filter rule add chain=nap-out-v6 comment="Discard other advertisements" disabled=no rule="reject;"
/routing filter rule add chain=blp-in-v6-jb comment="Discard default route and private ranges" disabled=no rule="jump ipv6martian;"
/routing filter rule add chain=blp-in-v6-jb comment="Do not accept own prefix" disabled=no rule="if (dst in bgp-networks-v6 && dst-len in 32-128) { reject; }"
/routing filter rule add chain=blp-in-v6-jb comment="Set localpref" disabled=no rule="set bgp-local-pref $jbblpprio; accept"
/routing filter rule add chain=blp-in-v6-ct comment="Discard default route and private ranges" disabled=no rule="jump ipv6martian;"
/routing filter rule add chain=blp-in-v6-ct comment="Do not accept own prefix" disabled=no rule="if (dst in bgp-networks-v6 && dst-len in 32-128) { reject; }"
/routing filter rule add chain=blp-in-v6-ct comment="Set localpref" disabled=no rule="set bgp-local-pref $ctblpprio; accept"
/routing filter rule add chain=blp-out-v6 comment="Advertise own range" disabled=no rule="if (dst in bgp-networks-v6 && dst-len == 32) { accept; }"
/routing filter rule add chain=blp-out-v6 comment="Discard other advertisements" disabled=no rule="reject;"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Default route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - IPv4-compatible IPv6 address deprecated by RFC4291" disabled=no rule="if (dst == ::/96) { reject;}"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Unspecified address" disabled=no rule="if (dst == ::) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Local host loopback address" disabled=no rule="if (dst == ::1) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - IPv4-mapped addresses" disabled=no rule="if (dst == ::ffff:0.0.0.0/96) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Compatible address (IPv4 format)" disabled=no rule="if (dst == ::224.0.0.0/100) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Compatible address (IPv4 format)" disabled=no rule="if (dst == ::127.0.0.0/104) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Compatible address (IPv4 format)" disabled=no rule="if (dst == ::/104) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Compatible address (IPv4 format)" disabled=no rule="if (dst == ::255.0.0.0/104) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Pool used for unspecified loopback and embedded IPv4 addresses" disabled=no rule="if (dst == ::/8) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - OSI NSAP-mapped prefix set (RFC4548) deprecated by RFC4048" disabled=no rule="if (dst == 200::/7) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Former 6bone now decommissioned" disabled=no rule="if (dst == 3ffe::/16) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Reserved by IANA for special purposes and documentation" disabled=no rule="if (dst == 2001:db8::/32) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Invalid 6to4 packets (IPv4 multicast)" disabled=no rule="if (dst == 2002:e000::/20) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Invalid 6to4 packets (IPv4 loopback)" disabled=no rule="if (dst == 2002:7f00::/24) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Invalid 6to4 packets (IPv4 default)" disabled=no rule="if (dst == 2002::/24) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Invalid 6to4 packets" disabled=no rule="if (dst == 2002:ff00::/24) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Invalid 6to4 packets (IPv4 private 10.0.0.0/8 network)" disabled=no rule="if (dst == 2002:a00::/24) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Invalid 6to4 packets (IPv4 private 172.16.0.0/12 network)" disabled=no rule="if (dst == 2002:ac10::/28) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Invalid 6to4 packets (IPv4 private 192.168.0.0/16 network)" disabled=no rule="if (dst == 2002:c0a8::/32) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Unicast Unique Local Addresses (ULA) RFC 4193" disabled=no rule="if (dst == fc00::/7) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Link-local Unicast" disabled=no rule="if (dst == fe80::/10) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Site-local Unicast deprecated by RFC 3879 (replaced by ULA)" disabled=no rule="if (dst == fec0::/10) { reject; }"
/routing filter rule add chain=ipv6martian comment="IPv6 Martian - Multicast" disabled=no rule="if (dst == ff00::/8) { reject; }"
}

# Define RPKI Filters

/routing filter rule add chain=rpki-nap-ct disabled=no rule="rpki-verify NAPCT" comment="Verify NAPCT"
/routing filter rule add chain=rpki-nap-ct disabled=no rule="if (rpki invalid) { reject } else { accept }" comment="Reject Invalid NAPCT"
/routing filter rule add chain=rpki-nap-jb disabled=no rule="rpki-verify NAPJB" comment="Verify NAPJB"
/routing filter rule add chain=rpki-nap-jb disabled=no rule="if (rpki invalid) { reject } else { accept }"  comment="Reject Invalid NAPJB"

# Peers required for IPT

if ($addipt=yes) do {
/routing/bgp/connection add connect=yes disabled=no listen=yes local.role=ebgp name=( "ipt-pri-v4-" . $iptpriname ) remote.address=$iptpriaddressv4 .as=$iptpriasn templates=( "template-ipt-pri-v4-" . $iptpriname )
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=no listen=yes local.role=ebgp name=( "ipt-pri-v6-" . $iptpriname ) remote.address=$iptpriaddressv6 .as=$iptpriasn templates=( "template-ipt-pri-v6-" . $iptpriname )}
}

# Peers required for NAP Johannesburg IPv4

/routing/bgp/connection add connect=yes disabled=no listen=yes local.role=ebgp name=nap-joburg-ipv4-collector remote.address=196.60.9.1 .as=37186 templates=template-nap-v4-jb
/routing/bgp/connection add connect=yes disabled=no listen=yes local.role=ebgp name=nap-joburg-ipv4-primary remote.address=196.60.9.2/32 .as=37195 templates=template-nap-v4-jb
/routing/bgp/connection add connect=yes disabled=no listen=yes local.role=ebgp name=nap-joburg-ipv4-secondary remote.address=196.60.9.3/32 .as=37195 templates=template-nap-v4-jb

# Peers required for NAP Cape Town IPv4

/routing/bgp/connection add connect=yes disabled=yes listen=yes local.role=ebgp name=nap-capetown-ipv4-collector remote.address=196.60.70.1 .as=37186 templates=template-nap-v4-ct
/routing/bgp/connection add connect=yes disabled=yes listen=yes local.role=ebgp name=nap-capetown-ipv4-primary remote.address=196.60.70.2 .as=37195 templates=template-nap-v4-ct
/routing/bgp/connection add connect=yes disabled=yes listen=yes local.role=ebgp name=nap-capetown-ipv4-secondary remote.address=196.60.70.3 .as=37195 templates=template-nap-v4-ct

# Peers required for NAP Johannesburg IPv6

if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=no listen=yes local.role=ebgp name=nap-joburg-ipv6-primary-collector remote.address=2001:43f8:6d0::1 .as=37186 templates=template-nap-v6-jb}
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=no listen=yes local.role=ebgp name=nap-joburg-ipv6-primary remote.address=2001:43f8:6d0::2 .as=37195 templates=template-nap-v6-jb}
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=no listen=yes local.role=ebgp name=nap-joburg-ipv6-secondary remote.address=2001:43f8:6d0::3 .as=37195 templates=template-nap-v6-jb}

# Peers required for NAP Cape Town IPv6

if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes listen=yes local.role=ebgp name=nap-capetown-ipv6-primary-collector remote.address=2001:43f8:6d1::1 .as=37186 template=template-nap-v6-ct}
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes listen=yes local.role=ebgp name=nap-capetown-ipv6-primary remote.address=2001:43f8:6d1::2 .as=37195 templates=template-nap-v6-ct}
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes listen=yes local.role=ebgp name=nap-capetown-ipv6-secondary remote.address=2001:43f8:6d1::3 .as=37195 templates=template-nap-v6-ct}

# Sample Bi Lateral Peers

/routing/bgp/connection add connect=yes disabled=yes listen=yes local.role=ebgp name=akamai-ipv4-primary-capetown output.filter-chain=blp-out-v4 remote.address=196.60.70.113 .as=20940 templates=template-blp-v4-ct
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v6-ct listen=yes local.role=ebgp name=akamai-ipv6-primary-capetown output.filter-chain=blp-out-v6 remote.address=2001:43f8:6d1::113 .as=20940 templates=template-blp-v6-ct}
/routing/bgp/connection add connect=yes disabled=yes listen=yes local.role=ebgp name=amazon-ipv4-primary-capetown output.filter-chain=blp-out-v4 remote.address=196.60.70.105 .as=16509 templates=template-blp-v4-ct
/routing/bgp/connection add connect=yes disabled=yes listen=yes local.role=ebgp name=amazon-ipv4-secondary-capetown output.filter-chain=blp-out-v4 remote.address=196.60.70.110 .as=16509 templates=template-blp-v4-ct
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v6-ct listen=yes local.role=ebgp name=amazon-ipv6-primary-capetown output.filter-chain=blp-out-v6 remote.address=2001:43f8:6d1::105 .as=16509 templates=template-blp-v6-ct}
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v6-ct listen=yes local.role=ebgp name=amazon-ipv6-secondary-capetown output.filter-chain=blp-out-v6 remote.address=2001:43f8:6d1::110 .as=16509 templates=template-blp-v6-ct}
/routing/bgp/connection add connect=yes disabled=yes listen=yes local.role=ebgp name=microsoft-ipv4-primary-capetown output.filter-chain=blp-out-v4 remote.address=196.60.70.47 .as=8075 templates=template-blp-v4-ct
/routing/bgp/connection add connect=yes disabled=yes listen=yes local.role=ebgp name=microsoft-ipv4-secondary-capetown output.filter-chain=blp-out-v4 remote.address=196.60.70.147 .as=8075 templates=template-blp-v4-ct
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v6-ct listen=yes local.role=ebgp name=microsoft-ipv6-primary-capetown output.filter-chain=blp-out-v6 remote.address=2001:43f8:6d1::47 .as=8075 templates=template-blp-v6-ct}
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v6-ct listen=yes local.role=ebgp name=microsoft-ipv6-secondary-capetown output.filter-chain=blp-out-v6 remote.address=2001:43f8:6d1::147 .as=8075 templates=template-blp-v6-ct}
/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v4-jb listen=yes local.role=ebgp name=netflix-jhb-ipv4-primary output.filter-chain=blp-out-v4 remote.address=196.60.8.80 .as=2906 templates=template-blp-v4-jb
/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v4-jb listen=yes local.role=ebgp name=netflix-jhb-ipv4-secondary output.filter-chain=blp-out-v4 remote.address=196.60.8.100 .as=2906 templates=template-blp-v4-jb
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v6-jb listen=yes local.role=ebgp name=netflix-jhb-ipv6-primary output.filter-chain=blp-out-v6 remote.address=2001:43f8:6d0::80 .as=2906 templates=template-blp-v6-jb}
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v6-jb listen=yes local.role=ebgp name=netflix-jhb-ipv6-secondary output.filter-chain=blp-out-v6 remote.address=2001:43f8:6d0::100 .as=2906 templates=template-blp-v6-jb}
/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v4-jb listen=yes local.role=ebgp name=apple-jhb-ipv4-primary output.filter-chain=blp-out-v4 remote.address=196.60.9.161 .as=714 templates=template-blp-v4-jb
/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v4-jb listen=yes local.role=ebgp name=apple-jhb-ipv4-secondary output.filter-chain=blp-out-v4 remote.address=196.60.9.162 .as=714 templates=template-blp-v4-jb
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v6-jb listen=yes local.role=ebgp name=apple-jhb-ipv6-primary output.filter-chain=blp-out-v6 remote.address=2001:43f8:6d0::9:161 .as=714 templates=template-blp-v6-jb}
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v6-jb listen=yes local.role=ebgp name=apple-jhb-ipv6-secondary output.filter-chain=blp-out-v6 remote.address=2001:43f8:6d0::9:162 .as=714 templates=template-blp-v6-jb}
/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v4-jb listen=yes local.role=ebgp name=facebook-jhb-ipv4-primary output.filter-chain=blp-out-v4 remote.address=196.60.9.15 .as=32934 templates=template-blp-v4-jb
/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v4-jb listen=yes local.role=ebgp name=facebook-jhb-ipv4-secondary output.filter-chain=blp-out-v4 remote.address=196.60.9.16 .as=32934 templates=template-blp-v4-jb
/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v4-jb listen=yes local.role=ebgp name=facebook-jhb-ipv4-tertiary output.filter-chain=blp-out-v4 remote.address=196.60.10.3 .as=32934 templates=template-blp-v4-jb
/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v4-jb listen=yes local.role=ebgp name=facebook-jhb-ipv4-quaternary output.filter-chain=blp-out-v4 remote.address=196.60.10.4 .as=32934 templates=template-blp-v4-jb
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v6-jb listen=yes local.role=ebgp name=facebook-jhb-ipv6-primary output.filter-chain=blp-out-v6 remote.address=2001:43f8:6d0::2934 .as=32934 templates=template-blp-v6-jb}
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v6-jb listen=yes local.role=ebgp name=facebook-jhb-ipv6-secondary output.filter-chain=blp-out-v6 remote.address=2001:43f8:6d0::934 .as=32934 templates=template-blp-v6-jb}
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v6-jb listen=yes local.role=ebgp name=facebook-jhb-ipv6-tertiary output.filter-chain=blp-out-v6 remote.address=2001:43f8:6d0::10:3 .as=32934 templates=template-blp-v6-jb}
if ($addipv6=yes) do={/routing/bgp/connection add connect=yes disabled=yes input.filter=blp-in-v6-jb listen=yes local.role=ebgp name=facebook-jhb-ipv6-quaternary output.filter-chain=blp-out-v6 remote.address=2001:43f8:6d0::10:4 .as=32934 templates=template-blp-v6-jb}
