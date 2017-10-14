#!/bin/bash -v
tempdeb=$(mktemp /tmp/debpackage.XXXXXXXXXXXXXXXXXX) || exit 1
wget -O "$tempdeb" https://apt.puppetlabs.com/puppet5-release-xenial.deb
dpkg -i "$tempdeb"
apt-get update
apt-get -y install puppetserver
/opt/puppetlabs/bin/puppet resource service puppet ensure=stopped enable=true
/opt/puppetlabs/bin/puppet resource service puppetserver ensure=stopped enable=true
# configure puppet agent, and puppetserver autosign
/opt/puppetlabs/bin/puppet config set server manager.borg.trek --section main
/opt/puppetlabs/bin/puppet config set autosign false --section master
# keys for hiera-eyaml TBA...
# r10 and control-repo:
/opt/puppetlabs/bin/puppet module install puppet-r10k
cat <<EOF > /var/tmp/r10k.pp
class { 'r10k':
  sources => {
    'puppet' => {
      'remote'  => 'https://github.com/githubgossin/control-repo-cr.git',
      'basedir' => "/etc/puppetlabs/code/environments",
      'prefix'  => false,
    },
  },
}
EOF
/opt/puppetlabs/bin/puppet apply /var/tmp/r10k.pp
r10k deploy environment -p
echo "$(ip a | grep -Eo 'inet ([0-9]*\.){3}[0-9]*' | tr -d 'inet ' | grep -v '^127') $(hostname).borg.trek $(hostname)" >> /etc/hosts
/opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
/opt/puppetlabs/bin/puppet resource service puppetserver ensure=running enable=true
/opt/puppetlabs/bin/puppet agent -t
cat <<EOF >> /etc/dhcp/dhclient.conf
supersede domain-name "borg.trek";
supersede domain-name-servers 127.0.0.1;
EOF
reboot

