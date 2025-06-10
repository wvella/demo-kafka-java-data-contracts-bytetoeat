# Producer Recipes v1
make down SERVICE=byte-to-eat-v1-docker-producer-recipes

# Consumer Recipes v1
make down SERVICE=byte-to-eat-v1-docker-consumer-recipes

# Producer Recipes v2
# ./helper-scripts/register-migration-rules.sh
make down SERVICE=byte-to-eat-v2-docker-producer-recipes

# Consumer Recipes v2
make down SERVICE=byte-to-eat-v2-docker-consumer-recipes

# Producer Orders
make down SERVICE=byte-to-eat-v1-docker-producer-orders

# Consumer Orders
make down SERVICE=byte-to-eat-v1-docker-consumer-orders
