# OCI Testing Experiments
The following is a small collection of scripts that can be used to work with the Open Container Initiative (OCI)
conformance testing environment to explore the landscape. 

The general organization: 

* Build a Vagrant machine, bootstrapping all necessary tools into the machine. The Vagrantfile and bootstrap exist for Fedora.
* Once the machine is up and running, ssh into the machine. 
* At this point one can run the OCI runtime conformance suite using runc. (Instructions below.)
* git clone the OCI test script(s) to the test machine, and one can experiment (initially running the conformance suite with Docker). 

# The Vagrant Machine
There are a number of dependencies for building the OCI tools. 
These are all pulled into the Vagrant machine via `bootstrap.sh` as specified in the Vagrantfile. 

* git
* make (so we need to pull in the development tools). 
* Go
* libseccomp
* ntpd is useful to keep the Vagrant machine time in sync depending upon the environment.
* jq is useful for parsing json files.

The OCI Tools are also pulled onto the machine with `bootstrap.sh`

* runc
* runtime-tools
* image-tools

Docker is  installed via `bootstrap.sh` such that the conformance suite can be run on Docker. 

The last thing the `bootstrap.sh` script does is to force the `vagrant` user and group on the tree. 
The bootstrap process seems to stamp `root` as owner and group on the OCI tools installation. 
I imagine the bootstrap.sh file could be used on a VM on a cloud service to pull in all the dependencies, 
but this final stage of stamping the vagrant owner/group on the OCI tree is probably less helpful in that case. 

# Running the OCI Runtime Tool Conformance Suite with runc

# Running the OCI Runtime Tool Conformance Suite with runc


