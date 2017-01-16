#
# test_docker.sh Run the OCI test suite within a Docker context
 
# Create a working directory and copy into it the OCI runtime-tools test binary, 
# the root filesystem for the OCI container bundle, and generate an
# appropriate config.json for the bundle. 

echo "Test Step 0: Create the workspace and the bundle"
mkdir test_docker
cd test_docker 
cp $HOME/work/src/github.com/opencontainers/runtime-tools/runtimetest .
cp $HOME/work/src/github.com/opencontainers/runtime-tools/rootfs.tar.gz .
oci-runtime-tool generate --output config.json --args '/runtimetest' --args '--log-level=debug'  --rootfs-path '.'

#
# Create a base docker image from the OCI bundle root filesystem, 
# and tag the base image for use in a Docker container build. 
echo "Test Step 1: Create a base Docker image from the OCI bundle rootfs."
ID=$(docker import rootfs.tar.gz)
docker tag $ID test/rootfs

#
# Create a simple dockerfile to take the base docker image that 
# contains the OCI bundle root file system, add the OCI runtime-tools
# test executable, the generated bundle config.json, and 
# setup the entry point to be the test test executable. 
# Build the Docker container. 
echo "Test Step 2: Create the Dockerfile and the Docker container for the test executable."
cat >Dockerfile <<-'EOF'
FROM test/rootfs
MAINTAINER Stephen R. Walli <stephen.walli@gmail.com>

COPY runtimetest /
COPY config.json /
ENTRYPOINT [ "/runtimetest", "--log-level=debug" ]
EOF

docker build -t test/runtimetest  .

# 
# Run the OCI runtime and image validators against a saved version of the newly built test container.
echo "Test Step 3: Validate the Docker image with the OCI image validator."
docker save -o runtimetest-archive.tar test/runtimetest
oci-runtime-tool validate runtimetest-archive.tar
../work/src/github.com/opencontainers/image-tools/oci-image-validate runtimetest-archive.tar

# 
# Run the OCI test executable container in Docker. 
echo "Test Step 4: Run the Docker container for the OCI runtime tests."
docker run -it --hostname mrsdalloway test/runtimetest 
