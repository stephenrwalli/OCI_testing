# OCI Testing Experiments
The following is a small collection of scripts that can be used to work with the Open Container Initiative (OCI)
testing environment to explore the landscape. 

The general organization: 

* Build a Fedora24-based Vagrant machine, bootstrapping all of the necessary tools into the machine. 
* Once the machine is up and running, ssh into the machine. 
* At this point one can run the OCI runtime conformance suite using runc. (Instructions below.)
* Clone the OCI test script(s), and one can begin to experiment, initially running the conformance suite with Docker. 

# The Fedora24 Machine
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

Docker is also installed via bootstrap.sh such that the conformance suite can be run on Docker. 

The last thing the `bootstrap.sh` script does is to force the vagrant user and group on the tree. 
The bootstrap process seems to stamp root as owner and group on the OCI tools installation. 


