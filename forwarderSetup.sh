#!/bin/sh
#
#  This scripts extends https://github.com/Azure/azure-quickstart-templates/tree/master/301-dns-forwarder
#
#  only doing all the sudos as cloud-init doesn't run as root, likely better to use Azure VM Extensions
#
#  Sets dnssec-validation no to make it possible to connect Amazone Route53
#
#  $1 is the forwarder, $2 is the vnet IP range
#  $3 is the zone, $2 forwarder for the zone
#

touch /tmp/forwarderSetup_start
echo "$@" > /tmp/forwarderSetup_params

#  Install Bind9
#  https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-a-caching-or-forwarding-dns-server-on-ubuntu-14-04
sudo apt-get update -y
sudo apt-get install bind9 -y

# configure Bind9 for forwarding
sudo cat > named.conf.options << EndOFNamedConfOptions
acl goodclients {
    $2;
    localhost;
    localnets;
};

options {
        directory "/var/cache/bind";

        recursion yes;

        allow-query { goodclients; };

        forwarders {
            $1;
        };
        forward only;

        dnssec-validation no;

        auth-nxdomain no;    # conform to RFC1035
        listen-on { any; };
};
zone "$3" in {
  type forward;
  forwarders { $4; };
  forward only;
};
EndOFNamedConfOptions

sudo cp named.conf.options /etc/bind
sudo service bind9 restart

touch /tmp/forwarderSetup_end
