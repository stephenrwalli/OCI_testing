# OCI Testing Experiments
The following is a small collection of scripts that can be used to work with the Open Container Initiative (OCI)
conformance testing environment to explore the landscape. 

The general organization: 

* Build a Vagrant machine, bootstrapping all necessary tools into the machine. The Vagrantfile and bootstrap build files exist for `Fedora` and `Ubuntu` in their respective directories. 
* Once the machine is up and running, one can ssh into the machine. 
* At this point one can run the OCI runtime conformance suite using runc (instructions below). The bootstrap environment for the vagrant machine should have all the tools and OCI tools on the machine to enable this. 
* `git clone` the OCI test script(s) (in `test_scripts`) to the test machine, and one can experiment (initially running the conformance suite with Docker). 

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
... [lots of output as the machine is built] ... 
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

# Running the OCI Runtime Conformance Suite with Other Runtimes
Running the OCI conformance suite in the context of `runc` is certainly interesting, 
and obviously the reference implementation of the OCI runtime specification should pass a conformance test suite for the specification. 
It becomes more interesting to determine how the OCI conformance suite adapts to other container run-times and implementations of the OCI runtime specification.

Essentially, 
one needs to take the same approach of building a container bundle around the conformance test environment,
manipulating it into the container runtime expected packaging, 
then invoking the container runtime.  

> N.B. These experiments have been around the investigating and testing 
> the conformance suite itself and in NO WAY should be used as an indicator of 
> conformance for real products (e.g. Docker, rkt). These experiments are done 
> using "current" software from multiple archives and in no way represent 
> products to be certified. Such certification work will rightly come out of 
> [Open Container Initiative Certification Working Group](https://github.com/opencontainers/certification). 

## Running the OCI Runtime Conformance Suite with Docker
Running the OCI runtime conformance suite with Docker means:
* Create a working directory, then using the OCI runtime tools,  
 - copy into it the OCI runtime-tools test binary, `runtimetest`,
 - the root filesystem tar archive for the OCI container bundle, `rootfs.tar.gz`, 
 - generate an appropriate config.json for the bundle with `oci-runtime-tool`.
* Create a base Docker image from the root filesystem tar archive (with `docker import`), and tag the image. 
* Create a simple `Dockerfile` to pull the parts together into a Docker image. 
* Run the Docker image. 
* Verify the image looks appropriate with `oci-runtime-tool` and `oci-image-validator` (based on the archive created with `docker save`). 

The steps start by creating a workspace and copying the OCI conformance test environment into it:
```
$ mkdir test_docker
$ cd test_docker
$ cp $HOME/work/src/github.com/opencontainers/runtime-tools/runtimetest .
$ cp $HOME/work/src/github.com/opencontainers/runtime-tools/rootfs.tar.gz .
$ oci-runtime-tool generate --output config.json --args '/runtimetest' --args '--log-level=debug'  --rootfs-path '.'
```

Create the base image from the tar archive:
```
$ ID=$(docker import rootfs.tar.gz)
$ docker tag $ID test/rootfs
```

The Dockerfile looks like: 
```
FROM test/rootfs
MAINTAINER Your Name <youremail@wherever.com>

COPY runtimetest /
COPY config.json /
ENTRYPOINT [ "/runtimetest", "--log-level=debug" ]
```
Build the docker container image: 
```
$ docker build -t test/runtimetest  .
```

Validate the container image: 
```
$ docker save -o runtimetest-archive.tar test/runtimetest
$ oci-runtime-tool validate runtimetest-archive.tar
$ $HOME/work/src/github.com/opencontainers/image-tools/oci-image-validate runtimetest-archive.tar
```

And run the conformance suite: 
```
$ docker run -it --hostname mrsdalloway test/runtimetest
```

This process has been encapsulated into a `test_docker.sh` shell script. 
All the steps described above are captured in the script. 
```
$ cd $HOME
$ git clone https://github.com/stephenrwalli/OCI_testing.git
...
$ cd OCI_testing/test_scripts/
$ ./test_docker.sh 
...
$
```

After running the script, there's a directory (`test_docker`) that contains the Docker container build out,  
as well as the saved and validated image (`runtimetest-archive.tar`). 
Dumping the archive of the validated image shows the layers that were built up as `docker build` worked through the `Dockerfile`. 
```
$ ls test_docker
config.json  Dockerfile  rootfs.tar.gz  runtimetest  runtimetest-archive.tar
$ tar tvf test_docker/runtimetest-archive.tar
-rw-r--r-- 0/0            2464 2017-01-17 23:30 689a40fc9e951eb544c3e1f690a33a417f8b7f7066d3b966eada0d8014003df8.json
drwxr-xr-x 0/0               0 2017-01-17 23:30 72956ba9b7a06654b3fc517989a78ee5f6be8cd52e7918ee9b1cd144cb94b769/
-rw-r--r-- 0/0               3 2017-01-17 23:30 72956ba9b7a06654b3fc517989a78ee5f6be8cd52e7918ee9b1cd144cb94b769/VERSION
-rw-r--r-- 0/0             388 2017-01-17 23:30 72956ba9b7a06654b3fc517989a78ee5f6be8cd52e7918ee9b1cd144cb94b769/json
-rw-r--r-- 0/0         2140160 2017-01-17 23:30 72956ba9b7a06654b3fc517989a78ee5f6be8cd52e7918ee9b1cd144cb94b769/layer.tar
drwxr-xr-x 0/0               0 2017-01-17 23:30 928238846208049056c8256379fb04a0858644e4bcd7a548e57d3ac1d1d95e04/
-rw-r--r-- 0/0               3 2017-01-17 23:30 928238846208049056c8256379fb04a0858644e4bcd7a548e57d3ac1d1d95e04/VERSION
-rw-r--r-- 0/0            1379 2017-01-17 23:30 928238846208049056c8256379fb04a0858644e4bcd7a548e57d3ac1d1d95e04/json
-rw-r--r-- 0/0           26624 2017-01-17 23:30 928238846208049056c8256379fb04a0858644e4bcd7a548e57d3ac1d1d95e04/layer.tar
drwxr-xr-x 0/0               0 2017-01-17 23:30 f5350bc7471f707cce96059017355178db741ea0d3cf8ad0a7b9185ea28d8027/
-rw-r--r-- 0/0               3 2017-01-17 23:30 f5350bc7471f707cce96059017355178db741ea0d3cf8ad0a7b9185ea28d8027/VERSION
-rw-r--r-- 0/0             464 2017-01-17 23:30 f5350bc7471f707cce96059017355178db741ea0d3cf8ad0a7b9185ea28d8027/json
-rw-r--r-- 0/0         4803072 2017-01-17 23:30 f5350bc7471f707cce96059017355178db741ea0d3cf8ad0a7b9185ea28d8027/layer.tar
-rw-r--r-- 0/0             366 1970-01-01 00:00 manifest.json
-rw-r--r-- 0/0              99 1970-01-01 00:00 repositories
[vagrant@localhost test_scripts]$
```

As the vagrant machine build out included `jq`, it is easy to inspect the various json files. 

## Running the OCI Runtime Conformance Suite with rkt
> N.B. This is still an active experiment. It has only been tested on the Ubuntu build so far. 
> Installing rkt/acbuild is still done by hand, and not as part of the Vagrant machine startup. 

First Install [rkt](https://coreos.com/blog/getting-started-with-rkt-1-0.html) and [acbuild](https://github.com/containers/build). 
```
$ wget https://github.com/coreos/rkt/releases/download/v1.0.0/rkt-v1.0.0.tar.gz
$ tar xfv rkt-v1.0.0.tar.gz
$ alias rkt="sudo '${PWD}/rkt-v1.0.0/rkt'"
$ echo 'alias rkt="sudo '${PWD}/rkt-v1.0.0/rkt'"' >> .profile 
$ cd ~
$ git clone https://github.com/containers/build acbuild
$ cd acbuild
$ ./build
$ cd ~
$ echo 'export ACBUILD_BIN_DIR=~/acbuild/bin' >> .profile
$ echo 'export PATH=$PATH:$ACBUILD_BIN_DIR' >> .profile
$ source .profile
```

To run the OCI conformance runtime suite with `rkt` requires a similar process to `Docker`. 
Essentially we need to move the conformance test executable and its supporting container bundle into a rkt image, 
then run the image. 
To build the image, the acbuild tool is required. 

Create a workspace and copy the conformance test environment into it:
```
$ mkdir test_rkt
$ cd test_rkt
$ cp $HOME/work/src/github.com/opencontainers/runtime-tools/runtimetest .
$ cp $HOME/work/src/github.com/opencontainers/runtime-tools/rootfs.tar.gz .
$ oci-runtime-tool generate --output config.json --args '/runtimetest' --args '--log-level=debug'  --rootfs-path '.'
```

We can create a script for `acbuild` to execute to create the pod definition for the container.
As with creating the Dockerfile (above), we add the conformance test executable,
and bundle config.json, and set the entry point.
> N.B. For now, because of a lack of experience with `rkt`, 
> the experiment doesn't create a base layer for the root filesystem. 
> If there is a better way to unpack the tar
> archive and load the rootfs into the pod image, please file an issue/pull request. 

```
$ cat >rktfile <<-EOF
begin
set-name test/rkt
copy runtimetest /runtimetest
copy config.json /config.json
set-exec /runtimetest
write test-rkt.aci
EOF
```

Build the rkt image.
```
$ acbuild script rktfile
Beginning build with an empty ACI
Setting name of ACI to test/rkt
Copying host:runtimetest to aci:/runtimetest
Copying host:config.json to aci:/config.json
Setting exec command [/runtimetest]
Writing ACI to test-rkt.aci
```

At this point we can run the rkt image. 
```
$ rkt run --insecure-options=image test-rkt.aci
image: using image from file /home/ubuntu/rkt-v1.0.0/stage1-coreos.aci
image: using image from file test-rkt.aci
run: group "rkt" not found, will use default gid when rendering images
networking: loading networks from /etc/rkt/net.d
networking: loading network default with type ptp
stage1: warning: error setting journal ACLs, you'll need root to read the pod journal: group "rkt" not found
[61126.742852] runtimetest[4]: TAP version 13
[61126.743101] runtimetest[4]: ok 1 - root filesystem
...
```

We can see the pod and images created:
```
$ rkt list
UUID		APP	IMAGE NAME	STATE	CREATED		STARTED		NETWORKS
5cdc19cd	rkt	test/rkt	exited	5 seconds ago	5 seconds ago
$ rkt image list 
ID			NAME					IMPORT TIME	LAST USED	SIZE	LATEST
sha512-2e6e6329a5e4	coreos.com/rkt/stage1-coreos:1.0.0	11 seconds ago	11 seconds ago	73MiB	false
sha512-e49fd669407f	test/rkt				11 seconds ago	11 seconds ago	9.2MiB	false
```

Cleaning up images and pods is done with `rkt image rm` and `rkt rm`. 


