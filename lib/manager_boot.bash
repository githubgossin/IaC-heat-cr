#!/bin/bash -v
tempdeb=$(mktemp /tmp/debpackage.XXXXXXXXXXXXXXXXXX) || exit 1
wget -O "$tempdeb" https://apt.puppetlabs.com/puppet5-release-bionic.deb
dpkg -i "$tempdeb"
apt-get update
apt-get -y install puppetserver pwgen
/opt/puppetlabs/bin/puppet resource service puppet ensure=stopped enable=true
/opt/puppetlabs/bin/puppet resource service puppetserver ensure=stopped enable=true
# configure puppet agent, and puppetserver autosign
/opt/puppetlabs/bin/puppet config set server manager.borg.trek --section main
/opt/puppetlabs/bin/puppet config set runinterval 300 --section main
/opt/puppetlabs/bin/puppet config set autosign true --section master
# keys for hiera-eyaml TBA...
# r10 and control-repo:
/opt/puppetlabs/bin/puppet module install puppet-r10k
cat <<EOF > /var/tmp/r10k.pp
class { 'r10k':
  version => '2.6.4',
  sources => {
    'puppet' => {
      'remote'  => 'https://github.com/githubgossin/control-repo-cr.git',
      'basedir' => '/etc/puppetlabs/code/environments',
      'prefix'  => false,
    },
  },
}
EOF
/opt/puppetlabs/bin/puppet apply /var/tmp/r10k.pp
r10k deploy environment -p
cd /etc/puppetlabs/code/environments/production/
bash ./new_keys_and_passwds.bash
# temp fix to have correct fqdn for puppet, before permanent fix in dhclient
# (which requires reboot)
echo "$(ip a | grep -Eo 'inet ([0-9]*\.){3}[0-9]*' | tr -d 'inet ' | grep -v '^127') $(hostname).borg.trek $(hostname)" >> /etc/hosts
/opt/puppetlabs/bin/puppet resource service puppetserver ensure=running enable=true
/opt/puppetlabs/bin/puppet agent -t # request certificate
/opt/puppetlabs/bin/puppet agent -t # configure manager
/opt/puppetlabs/bin/puppet agent -t # once more to update exported resources
/opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
# permanent fix for domainname
cat <<EOF >> /etc/netplan/50-cloud-init.yaml
            nameservers:
                search: [borg.trek]
                addresses: [127.0.0.1]
EOF
netplan apply

#wc_notify --data-binary '{"status": "SUCCESS"}'
