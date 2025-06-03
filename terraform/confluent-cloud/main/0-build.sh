# Producer Recipes v1
make build SERVICE=byte-to-eat-v1-docker-producer-recipes IMAGE_NAME=byte-to-eat-docker-producer-recipes
make up SERVICE=byte-to-eat-v1-docker-producer-recipes
# make logs SERVICE=byte-to-eat-v1-docker-producer-recipes

# Producer Recipes v2
make build SERVICE=byte-to-eat-v2-docker-producer-recipes IMAGE_NAME=byte-to-eat-docker-producer-recipes IMAGE_TAG=2.0.0
# ./helper-scripts/register-migration-rules.sh
# make up SERVICE=byte-to-eat-v2-docker-producer-recipes
# make logs SERVICE=byte-to-eat-v2-docker-producer-recipes

# Consumer Recipes v2
make build SERVICE=byte-to-eat-v2-docker-consumer-recipes IMAGE_NAME=byte-to-eat-docker-consumer-recipes IMAGE_TAG=2.0.0
# make up SERVICE=byte-to-eat-v2-docker-consumer-recipes
# make logs SERVICE=byte-to-eat-v2-docker-consumer-recipes

# Producer Orders
make build SERVICE=byte-to-eat-v1-docker-producer-orders IMAGE_NAME=byte-to-eat-docker-producer-orders
make up SERVICE=byte-to-eat-v1-docker-producer-orders
# make logs SERVICE=byte-to-eat-v1-docker-producer-orders

# Consumer Orders
make build SERVICE=byte-to-eat-v1-docker-consumer-orders IMAGE_NAME=byte-to-eat-docker-consumer-orders
make up SERVICE=byte-to-eat-v1-docker-consumer-orders
# make logs SERVICE=byte-to-eat-v1-docker-consumer-orders
