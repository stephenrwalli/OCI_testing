#!/usr/bin/env bash

sudo dnf -y update
# On the vagrant machine ... 
# Set up ntp to keep the vagrant machine in time (vagrant/virtualbox loses sync when some hosts sleep.)
sudo yum -y install ntp

# Lots of json files so having jq to pretty print is useful
sudo dnf -y install jq

# Install git
sudo dnf -y install git

# Install go (Current stable as of this writing is 1.7.4)
sudo dnf -y install go
mkdir -p /home/vagrant/work
echo 'export GOPATH=/home/vagrant/work' >> /home/vagrant/.bashrc
echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/vagrant/.bashrc
echo 'set -o vi' >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc

# make isn't present ... 
sudo dnf -y install @development-tools

# Add seccomp 
sudo dnf -y install libseccomp-devel

# You now have an OCI ready Fedora 24 machine in VirtualBox. 
# Almost. There are still golang man dependencies to install for runtime-tools
# You might want to add the export lines to your .profile

# Add runc
mkdir -p /home/vagrant/work/src/github.com/opencontainers
cd /home/vagrant/work/src/github.com/opencontainers
git clone https://github.com/opencontainers/runc
cd runc
make
sudo make install

# Add runtime-tools
cd /home/vagrant/work/src/github.com/opencontainers
git clone https://github.com/opencontainers/runtime-tools
cd runtime-tools
make
# N.B. It is unclear what part Godeps presently plays. Because
# if I'm reading Godep.json correctly, it was last run a while ago. 
# Add man dependencies ... 
go get github.com/russross/blackfriday
go install github.com/russross/blackfriday
go get github.com/cpuguy83/go-md2man
go install github.com/cpuguy83/go-md2man
sudo install -m 755 $GOPATH/bin/go-md2man /usr/bin
sudo make install 

# Add image-tools
cd /home/vagrant/work/src/github.com/opencontainers
git clone https://github.com/opencontainers/image-tools.git
cd image-tools
make tools

# Adding Docker
sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/fedora/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
sudo dnf -y install docker-engine

sudo systemctl enable docker.service
sudo systemctl start docker

sudo usermod -aG docker vagrant

sudo systemctl enable docker

# Add rkt

#
# Fix ownership of bootstrapped files to vagrant user
sudo chown -R vagrant /home/vagrant/work
sudo chgrp -R vagrant /home/vagrant/work

