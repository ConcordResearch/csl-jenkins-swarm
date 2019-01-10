#!/bin/bash
export STACK_NAME=${$1:=dev}
docker stack ps ${STACK_NAME} --format "{{.Error}}" --no-trunc
