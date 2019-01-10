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
echo "Using these images:"
echo ""
echo "MASTER_IMAGE_NAME=${MASTER_IMAGE_NAME}"
echo "NODE_IMAGE_NAME=${NODE_IMAGE_NAME}"

echo "Go back to host docker"
eval $(docker-machine env -u)

echo ""
echo "Exporting local images so they can be copied to each docker-machine."
echo "This should be faster then pulling from a registry."
docker image save "${MASTER_IMAGE_NAME}" > /tmp/jm.tar
docker image save "${NODE_IMAGE_NAME}" > /tmp/jn.tar

echo ""
echo "Createing jenkins master dir on all nodes"
echo ""
echo "Getting the names of all running docker-machines"
read -d "\n" -a NODES <<< $(docker-machine ls -f {{.Name}})

NODES_LEN=${#NODES[@]}
LEADER_NODE="${NODES[0]}"

echo "Creating jenkins master directories on each docker-machine"
for (( index=0; index<${NODES_LEN}; index++ ));
do
  eval $(docker-machine env ${NODES[index]})
  docker-machine status ${NODES[index]}# &> /dev/null
  sleep 2s
  retVal=$?
  echo $retVal
  if [ $retVal -eq 0 ]; then
      DIR="/data/jenkins-master"
      echo "Making '${DIR}' on '${NODES[index]}'"
      docker-machine ssh "${NODES[index]}" sudo mkdir -p "${DIR}"
      docker-machine ssh "${NODES[index]}" sudo chown -R docker:staff "${DIR}"

      echo "Importing local images so they can be copied to each docker-machine."
      docker load -i /tmp/jm.tar
      docker load -i /tmp/jn.tar
  fi
done

eval $(docker-machine env ${LEADER_NODE})

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

