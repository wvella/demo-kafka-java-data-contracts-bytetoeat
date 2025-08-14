#!/bin/bash
# export DOCKER_USERNAME=xyz

export IMAGE_TAG=1.0.0
# TODO: Refactor to parameterize versions
# Producer Recipes v1
make build-multi-arch SERVICE=byte-to-eat-v1-docker-producer-recipes IMAGE_NAME=byte-to-eat-docker-producer-recipes IMAGE_TAG=2.0.0

# Consumer Recipes v1
make build-multi-arch SERVICE=byte-to-eat-v1-docker-consumer-recipes IMAGE_NAME=byte-to-eat-docker-consumer-recipes IMAGE_TAG=2.0.0

# Producer Recipes v2
make build-multi-arch SERVICE=byte-to-eat-v2-docker-producer-recipes IMAGE_NAME=byte-to-eat-docker-producer-recipes IMAGE_TAG=3.0.0

# Consumer Recipes v2
make build-multi-arch SERVICE=byte-to-eat-v2-docker-consumer-recipes IMAGE_NAME=byte-to-eat-docker-consumer-recipes IMAGE_TAG=3.0.0

# Producer Orders
make build-multi-arch SERVICE=byte-to-eat-v1-docker-producer-orders IMAGE_NAME=byte-to-eat-docker-producer-orders IMAGE_TAG=2.0.0

# Consumer Orders
make build-multi-arch SERVICE=byte-to-eat-v1-docker-consumer-orders IMAGE_NAME=byte-to-eat-docker-consumer-orders IMAGE_TAG=2.0.0
