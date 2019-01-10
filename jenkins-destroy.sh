#!/bin/bash

# Maybe make conditional
export STACK_NAME=${STACK_NAME:=dev}
docker stack rm ${STACK_NAME}
docker secret rm $(docker secret ls -q)
