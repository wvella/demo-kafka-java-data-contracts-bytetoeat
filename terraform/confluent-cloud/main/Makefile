SEMVER=$(shell cat VERSION)
DOCKER_USERNAME=username

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

build: java-build
	docker build --tag $(IMAGE_NAME):$(IMAGE_TAG) -f $(DOCKER_DIR)/Dockerfile $(DOCKER_DIR)

up:
	./helper-scripts/generate-$(SERVICE)-config.sh
	docker compose -f $(DOCKER_DIR)/docker-compose.yml up -d

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
