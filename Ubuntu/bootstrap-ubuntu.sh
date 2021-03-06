#!/usr/bin/env bash

sudo apt-get -y update
sudo apt-get -y upgrade 
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y

# On the vagrant machine ... 
# Set up ntp to keep the vagrant machine in time (vagrant/virtualbox loses sync when some hosts sleep.)
sudo apt-get -y install ntp ntpdate

# Lots of json files so having jq to pretty print is useful
sudo apt-get -y install jq

# Install git
sudo apt-get -y install git

# Install go (Current stable is 1.8.x, but xenial seems to be stuck on 1.6.2)
# So I apt-get install, but then manually update. I appreciate this is probably too much.
sudo apt-get -y install golang-go
wget https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz
sudo tar -xvf go1.8.3.linux-amd64.tar.gz
sudo mv go /usr/local
mkdir -p /home/ubuntu/work
echo 'export GOROOT=/usr/local/go' >> /home/ubuntu/.bashrc
echo 'export GOPATH=/home/ubuntu/work' >> /home/ubuntu/.bashrc
echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> /home/ubuntu/.bashrc
echo 'set -o vi' >> /home/ubuntu/.bashrc
echo 'export GOROOT=/usr/local/go' >> /home/ubuntu/.bashrc
echo 'export GOPATH=/home/ubuntu/work' >> /home/ubuntu/.profile
echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> /home/ubuntu/.profile 
echo 'set -o vi' >> /home/ubuntu/.profile
source /home/ubuntu/.profile

# Add seccomp 
sudo apt-get -y install libseccomp-dev

# You now have an OCI ready Ubuntu Xenial machine in VirtualBox. 
# Almost. There are still golang man dependencies to install for runtime-tools
# You might want to add the export lines to your .profile

# Add runc
mkdir -p /home/ubuntu/work/src/github.com/opencontainers
cd /home/ubuntu/work/src/github.com/opencontainers
git clone https://github.com/opencontainers/runc
cd runc
make
sudo make install

# Add runtime-tools
cd /home/ubuntu/work/src/github.com/opencontainers
git clone https://github.com/opencontainers/runtime-tools
cd runtime-tools
make 
# N.B. It is unclear what part Godeps presently plays. Because
# if I'm reading Godep.json correctly, it was last run a while ago. 
# Add man dependencies ... 
go get github.com/russross/blackfriday
go get github.com/cpuguy83/go-md2man
sudo install -m 755 $GOPATH/bin/go-md2man /usr/bin
sudo make install 

# Add image-tools
cd /home/ubuntu/work/src/github.com/opencontainers
git clone https://github.com/opencontainers/image-tools.git
go get -d github.com/opencontainers/image-tools/cmd/oci-image-tool
cd $GOPATH/src/github.com/opencontainers/image-tools/
make all
sudo make install

# Adding Docker
sudo apt-get -y install apt-transport-https ca-certificates
sudo apt-key adv \
               --keyserver hkp://ha.pool.sks-keyservers.net:80 \
               --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get -y update
sudo apt-get -y install docker-engine

# sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual
sudo service docker start 
#sudo groupadd docker
sudo usermod -aG docker ubuntu

sudo apt-get -y update
sudo apt-get -y upgrade 

# Fix ownership of bootstrapped files to vagrant user
sudo chown -R ubuntu /home/ubuntu/work
sudo chgrp -R ubuntu /home/ubuntu/work

