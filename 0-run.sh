#!/bin/bash

# Producer Recipes v1
make up SERVICE=byte-to-eat-v1-docker-producer-recipes
# make logs SERVICE=byte-to-eat-v1-docker-producer-recipes

# Consumer Recipes v1
make up SERVICE=byte-to-eat-v1-docker-consumer-recipes
# make logs SERVICE=byte-to-eat-v1-docker-consumer-recipes

# Producer Recipes v2
# ./helper-scripts/register-migration-rules.sh
# make up SERVICE=byte-to-eat-v2-docker-producer-recipes
# make logs SERVICE=byte-to-eat-v2-docker-producer-recipes

# Consumer Recipes v2
# make up SERVICE=byte-to-eat-v2-docker-consumer-recipes
# make logs SERVICE=byte-to-eat-v2-docker-consumer-recipes

# Producer Orders
make up SERVICE=byte-to-eat-v1-docker-producer-orders
# make logs SERVICE=byte-to-eat-v1-docker-producer-orders

# Consumer Orders
make up SERVICE=byte-to-eat-v1-docker-consumer-orders
# make logs SERVICE=byte-to-eat-v1-docker-consumer-orders
