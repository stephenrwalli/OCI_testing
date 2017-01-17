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
* Build `runtimetest` (the conformance test binary), and `oci-runtime-tool`. 
* Build a container bundle in a directory that will be the "root" of the bundle. This involves:
 - Unpacking the tar archive of the rootfs.
 - Copying the `runtimetest` binary into the root. 
 - Using `oci-runtime-test` to generate a `config.json` file at the root.
* Using `runc` to create and run the container from the bundle. 

There is a shell script, `test_runtime.sh`, that is part of the OCI runtime tools that does this work and a little more.
There is/was a problem in the script towards the end where it attempts to "start" the container, rather than "run" it. 
It is fixed by changing the line from: 

`TESTCMD="${RUNTIME} start $(uuidgen)"`

to:

`TESTCMD="${RUNTIME} run $(uuidgen)"`

So once you start your vagrant machine and login via ssh, a simple run will look something like the following:
```
$ cd work/src/github.com/opencontainers/runtime-tools/
$ sudo ./test_runtime.sh -r $(which runc) 
sudo ./test_runtime.sh -r $(which runc)
-----------------------------------------------------------------------------------
VALIDATING RUNTIME: /usr/local/sbin/runc
-----------------------------------------------------------------------------------
TAP version 13
ok 1 - root filesystem
ok 2 - hostname
ok 3 - mounts
ok 4 - capabilities
ok 5 - default symlinks
ok 6 - default file system
ok 7 - default devices
ok 8 - linux devices
ok 9 - linux process
ok 10 - masked paths
ok 11 - oom score adj
ok 12 - read only paths
ok 13 - rlimits
ok 14 - sysctls
ok 15 - uid mappings
ok 16 - gid mappings
1..16
Runtime /usr/local/sbin/runc passed validation
```

# Running the OCI Runtime Conformance Suite with Docker
Running the OCI conformance suite in the context of `runc` is certainly interesting, 
and obviously the reference implementation of the OCI runtime specification should pass a conformance test suite for the specification. 
It becomes more interesting to determine how other container run-times and implementations of the OCI runtime specification behave, 
and how the OCI conformance suite adapts to other environments. 

Essentially, one needs to take the same approach of building a container bundle around the conformance test environment, 
then invoking the new container runtime.  For Docker, that means:
* Create a working directory 
 - copy into it the OCI runtime-tools test binary,
 - the root filesystem tar archive for the OCI container bundle, 
 - generate an appropriate config.json for the bundle with `oci-runtime-tool`.
* Create a base Docker image from the root filesystem tar archive (with `import`), and tag the image. 
* Create a simple `Dockerfile` to pull the parts together into a Docker image. 
* Run the Docker image. 
* Verify the image looks appropriate with `oci-runtime-tool` and `oci-image-validator` (based on the archive created with `save`). 

The Dockerfile looks like: 
```
FROM test/rootfs
MAINTAINER Stephen R. Walli <stephen.walli@gmail.com>

COPY runtimetest /
COPY config.json /
ENTRYPOINT [ "/runtimetest", "--log-level=debug" ]
```

This process has been encapsulated into a `test_docker.sh` shell script. 
```
$ cd $HOME
$ git clone https://github.com/stephenrwalli/OCI_testing.git
...
$ cd OCI_testing/test_scripts/
$ ./test_docker.sh 
...
```




