# OCI Testing Experiments
The following is a small collection of scripts that can be used to work with the Open Container Initiative (OCI)
testing environment to explore the landscape. 

In general, we build a Fedora24-based Vagrant machine, bootstrapping all of the necessary tools into the machine. 
Once the machine is up and running, ssh into the machine, clone the OCI test script(s), and you can begin to experiment. 

# The Fedora24 Machine
There are a number of dependencies for building the OCI tools. 
These are all pulled into the Vagrant machine via bootstrap.sh as specified in the Vagrantfile. 

* git
* make (so we need to pull in the development tools). 
* Go
* libseccomp
* ntpd is useful to keep the Vagrant machine time in sync depending upon the environment.
* jq is useful for parsing json files.

The OCI Tools
* runc
* runtime-tools
* image-tools

After getting a run through of the run-time tools (the OCI runtime conformance suite), 
the next experiment was to get the conformance suite to run on Docker, 
so we also need to install current Docker on the Vagrant machine. 

The last thing the bootstrap script does is to force the vagrant user and group on the tree. 
The bootstrap process seems to stamp root as owner and group on the OCI tools installation. 


