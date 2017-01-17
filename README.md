# OCI Testing Experiments
The following is a small collection of scripts that can be used to work with the Open Container Initiative (OCI)
conformance testing environment to explore the landscape. 

The general organization: 

* Build a Vagrant machine, bootstrapping all necessary tools into the machine. The Vagrantfile and bootstrap exist for Fedora and Ubuntu.
* Once the machine is up and running, ssh into the machine. 
* At this point one can run the OCI runtime conformance suite using runc. (Instructions below.)
* git clone the OCI test script(s) to the test machine, and one can experiment (initially running the conformance suite with Docker). 

# The Vagrant Machine
There are a number of dependencies for building the OCI tools. 
These are all pulled into the Vagrant machine via `bootstrap-[platform].sh` as specified in the Vagrantfile. 

* git
* make (which is typically bundled with other development platform tools) 
* Go
* libseccomp
* ntpd (Fedora) is useful to keep the Vagrant machine time in sync depending upon the environment.
* jq is useful for parsing json files.

The OCI Tools are also pulled onto the machine with `bootstrap-[platform].sh`

* runc
* runtime-tools (These tools have further github dependencies for go.) 
* image-tools

Docker is installed such that the conformance suite can be run on Docker. 
The plan will be to get `rkt` running next. 

The last thing the `bootstrap-[platform].sh` script does is to force a platform reasonable user and group on the OCI installed tools tree. 
The vagrant bootstrap process seems to stamp `root` as owner and group on the OCI tools installation. 
I imagine the `bootstrap-[platform].sh` file could be used on a VM on a cloud service to pull in all the dependencies, 
but this final stage of stamping the vagrant owner/group on the OCI tree is probably less helpful in that case. 

## Starting Your Vagrant Machine
If you've not worked with Vagrant before now, install it on your machine. Instructions can be found on the [Vagrant site](https://www.vagrantup.com/). Once vagrant is installed, `git clone` this project into a working directory. 

```
$ git clone https://github.com/stephenrwalli/OCI_testing.git
$ cd OCI_testing/<plaform>
$ ls
Vagrantfile           bootstrap-<platform>.sh
```

It doesn't matter what platform you choose. Pick the one with which you're most familiar. 
From this directory, you can now issue commands to bring your vagrant machine up, and connect to it. 

```
$ vagrant up
...
$ vagrant ssh
```

You are now logged into a home directory on a known configured machine ready to use the OCI conformance testing tools. 

# Running the OCI Runtime Conformance Suite with runc
This process is rightly described on the [OCI Runtime Tools site](https://github.com/opencontainers/runtime-tools). 
The general process of running the OCI conformance test environment is:
* Build the conformance test binary, `runtimetest`, and `oci-runtime-tool`. 
* Build a container bundle in a directory that will be the "root" of the bundle. This involves:
 - Unpacking the tar archive of the rootfs.
 - Copying the `runtimetest` binary into the root. 
 - Using `oci-runtime-test` to generate a `config.json` file at the root.
* Using `runc` to create and run the container from the bundle. 

There is a shell script, `test_runtime.sh`, that is part of the OCI runtime tools that does this work and a little more.

```
$ sudo ./test_runtime.sh -r $(which runc) -l debug
-----------------------------------------------------------------------------------
VALIDATING RUNTIME: /usr/local/sbin/runc
-----------------------------------------------------------------------------------
time="2017-01-13T22:58:46Z" level=debug msg="validating root filesystem"
time="2017-01-13T22:58:46Z" level=debug msg="validating hostname"
time="2017-01-13T22:58:46Z" level=debug msg="validating mounts exist"
time="2017-01-13T22:58:46Z" level=debug msg="validating capabilities"
time="2017-01-13T22:58:46Z" level=debug msg="validating linux default filesystem"
time="2017-01-13T22:58:46Z" level=debug msg="validating linux default devices"
time="2017-01-13T22:58:46Z" level=debug msg="validating linux devices"
time="2017-01-13T22:58:46Z" level=debug msg="validating container process"
time="2017-01-13T22:58:46Z" level=debug msg="validating maskedPaths"
time="2017-01-13T22:58:46Z" level=debug msg="validating oomScoreAdj"
time="2017-01-13T22:58:46Z" level=debug msg="validating readonlyPaths"
time="2017-01-13T22:58:46Z" level=debug msg="validating rlimits"
time="2017-01-13T22:58:46Z" level=debug msg="validating sysctls"
time="2017-01-13T22:58:46Z" level=debug msg="validating uidMappings"
time="2017-01-13T22:58:46Z" level=debug msg="validating gidMappings"
Runtime /usr/local/sbin/runc passed validation
```

# Running the OCI Runtime Conformance Suite with Docker


