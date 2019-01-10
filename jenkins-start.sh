#!/bin/bash
secret_exists () {
    secret_to_check=$1
    docker secret ls --filter name="${secret_to_check}" | grep -c "${secret_to_check}"
    return $?
}

export STACK_NAME=${STACK_NAME:=dev}
export JENKINS_VERSION=${JENKINS_VERSION:="2.157"}

DEFAULT_MASTER_IMAGE="csc/jenkins:${JENKINS_VERSION}"
export MASTER_IMAGE_NAME="${MASTER_IMAGE_NAME:=$DEFAULT_MASTER_IMAGE}"

DEFAULT_NODE_IMAGE="csc/jenkins-node:${JENKINS_VERSION}"
export NODE_IMAGE_NAME="${NODE_IMAGE_NAME:=$DEFAULT_NODE_IMAGE}"

echo ""
echo "Creating swarmm secrets"
has_secret=$( secret_exists "jenkinsUser" )
if [ $has_secret -eq 0 ]; then
    echo admin | docker secret create jenkinsUser -
fi

has_secret=$( secret_exists "jenkinsPassword" )
if [ "$has_secret" -eq 0 ]; then
    echo admin | docker secret create jenkinsPassword -
fi

has_secret=$( secret_exists "jenkinsSwarm" )
if [ "$has_secret" -eq 0 ]; then
    echo -master http://jenkins-master:8080 -password admin -username admin | docker secret create jenkinsSwarm -
fi

echo ""
echo "Starting jenkins stack"
docker stack deploy --compose-file jenkins-swarm.yml ${STACK_NAME}
#docker stack deploy --compose-file jenkins-master-stack.yml ${STACK_NAME}
#docker stack deploy --compose-file jenkins-nodes.yml ${STACK_NAME}

