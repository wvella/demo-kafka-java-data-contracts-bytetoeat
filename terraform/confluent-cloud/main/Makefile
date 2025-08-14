SEMVER=$(shell cat VERSION)
DOCKER_USERNAME ?= wvella

SERVICE ?= NULL
IMAGE_NAME ?= $(SERVICE)
IMAGE_TAG ?= $(SEMVER)
DOCKER_DIR=../../../$(SERVICE)
JAVA_BUILD_DIR=$(DOCKER_DIR)

define highlight_logs
awk '{line=$$0; \
    if (line ~ /ERROR/) {printf "\033[31m%s\033[0m\n", line} \
    else if (line ~ /WARN/) {printf "\033[33m%s\033[0m\n", line} \
    else if (line ~ /INFO/) {printf "\033[32m%s\033[0m\n", line} \
    else {print line}}'
endef

java-build:
	cd $(JAVA_BUILD_DIR) && mvn clean package

# multi-arch requires a push at the same time
build-multi-arch: java-build
	docker buildx build --push --platform linux/amd64,linux/arm64/v8 --tag $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG) --tag $(DOCKER_USERNAME)/$(IMAGE_NAME):latest -f $(DOCKER_DIR)/Dockerfile $(DOCKER_DIR)

build: java-build
#For Intel use linux/amd64
	docker buildx build --tag $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG) -f $(DOCKER_DIR)/Dockerfile $(DOCKER_DIR)

docker-push:
	docker tag $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG) $(DOCKER_USERNAME)/$(IMAGE_NAME):latest
	docker push $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(DOCKER_USERNAME)/$(IMAGE_NAME):latest

docker-inspect:
	docker inspect $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG) --format='{{.Architecture}}'

#The - before the command ignores errors if the container is not running.
up:
	./helper-scripts/generate-$(SERVICE)-config.sh
	-docker compose -f $(DOCKER_DIR)/docker-compose.yml rm -sf
	docker compose -f $(DOCKER_DIR)/docker-compose.yml up -d

down:
	-docker compose -f $(DOCKER_DIR)/docker-compose.yml rm -sf

logs:
	docker compose -f $(DOCKER_DIR)/docker-compose.yml logs -f | $(highlight_logs)

#Summary Table:
#Command	When to use
#bump-patch	Bug fixes, minor changes, no new features
#bump-minor	Add features, backwards-compatible improvements
#bump-major	Breaking changes, incompatible API changes

bump-patch:
	@old=$$(cat VERSION); \
	major=$${old%%.*}; \
	minor_patch=$${old#*.}; \
	minor=$${minor_patch%%.*}; \
	patch=$${old##*.}; \
	new="$$major.$$minor.$$((patch+1))"; \
	echo $$new > VERSION; \
	echo "Bumped patch version: $$old -> $$new"

bump-minor:
	@old=$$(cat VERSION); \
	major=$${old%%.*}; \
	minor_patch=$${old#*.}; \
	minor=$${minor_patch%%.*}; \
    new="$$major.$$((minor+1)).0"; \
    echo $$new > VERSION; \
	echo "Bumped minor version: $$old -> $$new"

bump-major:
	@old=$$(cat VERSION); \
	major=$${old%%.*}; \
	new="$$((major+1)).0.0"; \
	echo $$new > VERSION; \
	echo "Bumped major version: $$old -> $$new"
