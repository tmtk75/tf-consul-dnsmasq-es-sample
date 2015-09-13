##
## Tasks
##
tf-plan: id_rsa.pub
	terraform plan

tf-apply: id_rsa.pub
	terraform apply

tf-refresh:
	terraform refresh

tf-destroy:
	terraform destroy

ping: hosts.ini
	ansible -i hosts.ini -m ping all

puppet: hosts.ini roles/puppet
	ansible-playbook -i hosts.ini playbook.puppet.yml

consul: hosts.ini roles/consul host_vars
	ansible-playbook -i hosts.ini playbook.consul.yml

join:
	ssh -F ssh-config `terraform output node1` /usr/local/sbin/consul join `terraform output node0`
	ssh -F ssh-config `terraform output node2` /usr/local/sbin/consul join `terraform output node0`
	ssh -F ssh-config `terraform output node3` /usr/local/sbin/consul join `terraform output node0`
	ssh -F ssh-config `terraform output node4` /usr/local/sbin/consul join `terraform output node0`

elasticsearch: hosts.ini
	ansible-playbook -i hosts.ini playbook.elasticsearch.yml


dnsmasq: hosts.ini roles/dnsmasq host_vars
	ansible-playbook -i hosts.ini playbook.dnsmasq.yml

consul-template: hosts.ini roles/consul-template host_vars
	ansible-playbook -i hosts.ini playbook.consul-template.yml

cleanall:
	rm -rf bin .e host_vars

##
## Generate files & dependencies
##
id_rsa id_rsa.pub:
	ssh-keygen -t rsa  -f id_rsa -N ""

hosts.ini: terraform.tfstate
	@echo "node0 ansible_ssh_host=`terraform output node0`"  > hosts.ini
	@echo "node1 ansible_ssh_host=`terraform output node1`" >> hosts.ini
	@echo "node2 ansible_ssh_host=`terraform output node2`" >> hosts.ini
	@echo "node3 ansible_ssh_host=`terraform output node3`" >> hosts.ini
	@echo "node4 ansible_ssh_host=`terraform output node4`" >> hosts.ini
	@echo "node5 ansible_ssh_host=`terraform output node5`" >> hosts.ini

host_vars: terraform.tfstate
	mkdir -p host_vars
	echo "server: true\nmy_nodename: node0"  > host_vars/node0.yml
	echo "server: true\nmy_nodename: node1"  > host_vars/node1.yml
	echo "server: true\nmy_nodename: node2"  > host_vars/node2.yml
	echo "server: false\nmy_nodename: node3" > host_vars/node3.yml
	echo "server: false\nmy_nodename: node4" > host_vars/node4.yml
	echo "server: false\nmy_nodename: node5" > host_vars/node5.yml

ssh: hosts.ini id_rsa
	ssh -F ssh-config `cat hosts.ini | peco | sed 's/^.*=//'`

roles/consul roles/puppet roles/elasticsearch roles/consul-template:
	ansible-galaxy install -r requirements.yml --force

##
## Show info
##
es-head:  hosts.ini id_rsa
	open http://`cat hosts.ini | peco | sed 's/^.*=//'`:9200/_plugin/head

consul-service:
	curl -s http://`cat hosts.ini | peco | sed 's/^.*=//'`:8500/v1/catalog/service/elasticsearch

consul-health:
	curl -s http://`cat hosts.ini | peco | sed 's/^.*=//'`:8500/v1/health/service/elasticsearch

##
## Example
##
es-tweet:
	curl -X PUT http://`cat hosts.ini | peco | sed 's/^.*=//'`:9200/twitter/tweet/1 -d @tweet.json

##
##
##
setup: jq peco ansible
bin:
	mkdir -p bin

## jq
jq: bin/jq
bin/jq: bin 
	curl -o bin/jq -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-osx-amd64
	chmod +x bin/jq

## peco
peco: bin/peco
bin/peco: bin
	(cd bin; \
	  curl -OL https://github.com/peco/peco/releases/download/v0.3.3/peco_darwin_amd64.zip; \
	  unzip -o peco_darwin_amd64.zip)
	ln -sf `pwd`/bin/peco_darwin_amd64/peco bin/peco

## ansible
ansible: .e/bin/ansible
.e/bin/ansible: .e/bin/pip2.7
	.e/bin/pip2.7 install ansible
.e/bin/pip2.7:
	virtualenv .e

## aws
aws: .e/bin/aws
.e/bin/aws: .e/bin/pip
	.e/bin/pip install awscli

