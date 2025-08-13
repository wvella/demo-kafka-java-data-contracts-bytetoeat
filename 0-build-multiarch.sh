#!/bin/bash
# export DOCKER_USERNAME=xyz

export IMAGE_TAG=1.0.0
# TODO: Refactor to parameterize versions
# Producer Recipes v1
make build-multi-arch SERVICE=byte-to-eat-v1-docker-producer-recipes IMAGE_NAME=byte-to-eat-recipe-producer-v1

# Consumer Recipes v1
make build-multi-arch SERVICE=byte-to-eat-v1-docker-consumer-recipes IMAGE_NAME=byte-to-eat-recipe-consumer-v1

# Producer Recipes v2
make build-multi-arch SERVICE=byte-to-eat-v2-docker-producer-recipes IMAGE_NAME=byte-to-eat-recipe-producer-v2

# Consumer Recipes v2
make build-multi-arch SERVICE=byte-to-eat-v2-docker-consumer-recipes IMAGE_NAME=byte-to-eat-recipe-consumer-v2

# Producer Orders
make build-multi-arch SERVICE=byte-to-eat-v1-docker-producer-orders IMAGE_NAME=byte-to-eat-order-producer

# Consumer Orders
make build-multi-arch SERVICE=byte-to-eat-v1-docker-consumer-orders IMAGE_NAME=byte-to-eat-order-consumer

export IMAGE_TAG=latest
# Producer Recipes v1
make build-multi-arch SERVICE=byte-to-eat-v1-docker-producer-recipes IMAGE_NAME=byte-to-eat-recipe-producer-v1

# Consumer Recipes v1
make build-multi-arch SERVICE=byte-to-eat-v1-docker-consumer-recipes IMAGE_NAME=byte-to-eat-recipe-consumer-v1

# Producer Recipes v2
make build-multi-arch SERVICE=byte-to-eat-v2-docker-producer-recipes IMAGE_NAME=byte-to-eat-recipe-producer-v2

# Consumer Recipes v2
make build-multi-arch SERVICE=byte-to-eat-v2-docker-consumer-recipes IMAGE_NAME=byte-to-eat-recipe-consumer-v2

# Producer Orders
make build-multi-arch SERVICE=byte-to-eat-v1-docker-producer-orders IMAGE_NAME=byte-to-eat-order-producer

# Consumer Orders
make build-multi-arch SERVICE=byte-to-eat-v1-docker-consumer-orders IMAGE_NAME=byte-to-eat-order-consumer