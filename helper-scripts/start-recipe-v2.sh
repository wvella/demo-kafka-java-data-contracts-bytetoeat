#!/bin/bash

# Is run from root directory

make up SERVICE=byte-to-eat-v2-docker-producer-recipes
make up SERVICE=byte-to-eat-v2-docker-consumer-recipes
