# Simple Cyber Range

This is a Heat template to launch a simple cyber range. The servers are initialized based on [this Puppet control repo](https://github.com/githubgossin/control-repo-cr).

Clone and launch in OpenStack with e.g.
```bash
# make sure you have security groups called default and linux
# edit iac_top_env.yaml and enter name of your keypair
git clone https://github.com/githubgossin/IaC-heat-cr.git
cd IaC-heat-cr
openstack stack create simple_cyber_range -t iac_top.yaml -e iac_top_env.yaml
```
## Troubleshooting
+ uchiwa server 500 error, [debug rabbitmq keys](https://www.rabbitmq.com/troubleshooting-ssl.html)
+ [logstash ssl](https://www.elastic.co/guide/en/beats/filebeat/current/configuring-ssl-logstash.html)
