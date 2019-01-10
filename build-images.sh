#!/bin/bash

cd jenkins-swarm-docker-master || exit

echo "Copying ssh keys for master"
mkdir -p master-ssh
cp -a ../ssh/ ./master-ssh/

export JENKINS_VERSION="2.157"
echo ""
echo "Building Jenkins master"
docker build -f Dockerfile \
    --build-arg JENKINS_VERSION=${JENKINS_VERSION} \
    -t csc/jenkins:${JENKINS_VERSION} \
    -t csc/jenkins:latest \
    .

cd ../jenkins-swarm-docker-slave || exit

echo ""
echo "Copying ssh keys for nodes"
mkdir -p node-ssh
cp -a ../ssh/ ./node-ssh/

export DOCKER_VERSION="18.06"
echo ""
echo "Building Jenkins node"
docker build -f Dockerfile \
    --build-arg DOCKER_VERSION=${DOCKER_VERSION} \
    -t csc/jenkins-node:${JENKINS_VERSION} \
    -t csc/jenkins-node:latest \
    .