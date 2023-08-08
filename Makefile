LAYER_NAME_PREFIX = rclone
RCLONE_VERSION = v1.63.1

build-amd64:
	mkdir -p build/layer-amd64/bin/ dist/
	wget -P build/ https://github.com/rclone/rclone/releases/download/$(RCLONE_VERSION)/rclone-$(RCLONE_VERSION)-linux-amd64.zip
	unzip -j build/rclone-$(RCLONE_VERSION)-linux-amd64.zip rclone-$(RCLONE_VERSION)-linux-amd64/rclone -d build/layer-amd64/bin/
	cd build/layer-amd64/ && zip -r ../../dist/layer-amd64.zip *

build-arm64:
	mkdir -p build/layer-arm64/bin/ dist/
	wget -P build/ https://github.com/rclone/rclone/releases/download/$(RCLONE_VERSION)/rclone-$(RCLONE_VERSION)-linux-arm64.zip
	unzip -j build/rclone-$(RCLONE_VERSION)-linux-arm64.zip rclone-$(RCLONE_VERSION)-linux-arm64/rclone -d build/layer-arm64/bin/
	cd build/layer-arm64/ && zip -r ../../dist/layer-arm64.zip *

.PHONY: deploy-amd64
deploy-amd64:
	aws lambda publish-layer-version --layer-name $(LAYER_NAME_PREFIX)-amd64 --compatible-architectures "x86_64" --description "Rclone $(RCLONE_VERSION)" --license-info "MIT" --zip-file fileb://dist/layer-amd64.zip

.PHONY: deploy-arm64
deploy-arm64:
	aws lambda publish-layer-version --layer-name $(LAYER_NAME_PREFIX)-arm64 --compatible-architectures "arm64" --description "Rclone $(RCLONE_VERSION)" --license-info "MIT" --zip-file fileb://dist/layer-arm64.zip

.PHONY: clean
clean:
	rm -rv build dist

.PHONY: all-amd64
all-amd64: build-amd64 deploy-amd64 clean

.PHONY: all-arm64
all-arm64: build-arm64 deploy-arm64 clean

.PHONY: all
all: all-amd64 all-arm64
