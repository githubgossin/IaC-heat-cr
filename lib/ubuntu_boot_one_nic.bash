#!/bin/bash -v
tempdeb=$(mktemp /tmp/debpackage.XXXXXXXXXXXXXXXXXX) || exit 1
wget -O "$tempdeb" https://apt.puppetlabs.com/puppet5-release-bionic.deb
dpkg -i "$tempdeb"
apt-get update
apt-get -y install puppet-agent
echo "$(ip a | grep -Eo 'inet ([0-9]*\.){3}[0-9]*' | tr -d 'inet ' | grep 192.168.180) $(hostname).borg.trek $(hostname)" >> /etc/hosts
echo "manager_ip_address manager.borg.trek manager" >> /etc/hosts
/opt/puppetlabs/bin/puppet resource service puppet ensure=stopped enable=true
/opt/puppetlabs/bin/puppet config set server manager.borg.trek --section main
/opt/puppetlabs/bin/puppet config set runinterval 300 --section main
/opt/puppetlabs/bin/puppet agent -t # request certificate
/opt/puppetlabs/bin/puppet agent -t # configure 
/opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
cat <<EOF >> /etc/netplan/50-cloud-init.yaml
            nameservers:
                search: [borg.trek]
                addresses: [dns_ip_address]
EOF
netplan apply
