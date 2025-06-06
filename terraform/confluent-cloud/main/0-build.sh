# Producer Recipes v1
make build SERVICE=byte-to-eat-v1-docker-producer-recipes IMAGE_NAME=byte-to-eat-docker-producer-recipes
make docker-push SERVICE=byte-to-eat-v1-docker-producer-recipes IMAGE_NAME=byte-to-eat-docker-producer-recipes

# Consumer Recipes v1
make build SERVICE=byte-to-eat-v1-docker-consumer-recipes IMAGE_NAME=byte-to-eat-docker-consumer-recipes
make docker-push SERVICE=byte-to-eat-v1-docker-consumer-recipes IMAGE_NAME=byte-to-eat-docker-consumer-recipes

# Producer Recipes v2
make build SERVICE=byte-to-eat-v2-docker-producer-recipes IMAGE_NAME=byte-to-eat-docker-producer-recipes IMAGE_TAG=2.0.0
make docker-push SERVICE=byte-to-eat-v2-docker-producer-recipes IMAGE_NAME=byte-to-eat-docker-producer-recipes IMAGE_TAG=2.0.0

# Consumer Recipes v2
make build SERVICE=byte-to-eat-v2-docker-consumer-recipes IMAGE_NAME=byte-to-eat-docker-consumer-recipes IMAGE_TAG=2.0.0
make docker-push SERVICE=byte-to-eat-v2-docker-consumer-recipes IMAGE_NAME=byte-to-eat-docker-consumer-recipes IMAGE_TAG=2.0.0

# Producer Orders
make build SERVICE=byte-to-eat-v1-docker-producer-orders IMAGE_NAME=byte-to-eat-docker-producer-orders IMAGE_TAG=1.0.1
make docker-push SERVICE=byte-to-eat-v1-docker-producer-orders IMAGE_NAME=byte-to-eat-docker-producer-orders IMAGE_TAG=1.0.1

# Consumer Orders
make build SERVICE=byte-to-eat-v1-docker-consumer-orders IMAGE_NAME=byte-to-eat-docker-consumer-orders
make docker-push SERVICE=byte-to-eat-v1-docker-consumer-orders IMAGE_NAME=byte-to-eat-docker-consumer-orders
