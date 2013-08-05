REQS = git apache2 python-vm-builder ruby debootstrap lxc apt-cacher-ng \
	virt-what lxctl fakeroot faketime zip unzip subversion bridge-utils

# remove torsocks to speed up testing
TORSOCKS = torsocks

.PHONY: all hostvm tbb

all: hostvm tbb

hostvm:
	vagrant destroy --force
	vagrant up
	vagrant ssh --command "sudo apt-get install -y tor torsocks"
	vagrant ssh --command "sudo $(TORSOCKS) apt-get update"
	
	# https://github.com/mitchellh/vagrant/issues/289
	vagrant ssh --command "sudo DEBIAN_FRONTEND=noninteractive $(TORSOCKS) \
		apt-get upgrade -y"
	
	vagrant reload
	vagrant ssh --command "sudo $(TORSOCKS) apt-get install -y $(REQS)"
	vagrant halt

tbb:
	vagrant up
	vagrant ssh --command "\
		if [ -d ~/gitian-builder ]; then \
			rm -rf ~/gitian-builder; \
		fi"
	
	vagrant ssh --command "$(TORSOCKS) \
		git clone -b tor-browser-builder-2 \
		'https://git.torproject.org/builders/gitian-builder.git' ~/gitian-builder"
	
	vagrant ssh --command "\
		if [ -d ~/tor-browser-bundle ]; then \
			rm -rf ~/tor-browser-bundle; \
		fi"
	
	vagrant ssh --command "\
		rsync -r --exclude=.vagrant \
		/tor-browser-bundle/ ~/tor-browser-bundle"
	
	vagrant ssh --command "cd ~/tor-browser-bundle/gitian && USE_LXC=1 make"
	
	vagrant ssh --command "cd ~/tor-browser-bundle/gitian && \
		cp -R 3.* /vagrant/"
	
	vagrant halt
