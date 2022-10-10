LAYER_NAME = rclone
RCLONE_VERSION = v1.59.2

build:
	mkdir -p build/layer/bin/ dist/
	wget -P build/ https://github.com/rclone/rclone/releases/download/$(RCLONE_VERSION)/rclone-$(RCLONE_VERSION)-linux-amd64.zip
	unzip -j build/rclone-$(RCLONE_VERSION)-linux-amd64.zip rclone-$(RCLONE_VERSION)-linux-amd64/rclone -d build/layer/bin/
	cd build/layer/ && zip -r ../../dist/layer.zip *

.PHONY: deploy
deploy:
	aws lambda publish-layer-version --layer-name $(LAYER_NAME) --description "Rclone $(RCLONE_VERSION)" --license-info "MIT" --zip-file fileb://dist/layer.zip

.PHONY: clean
clean:
	rm -rv build dist

.PHONY: all
all: build deploy clean
