PAK_NAME := $(shell jq -r .name pak.json)

ARCHITECTURES := arm arm64
PLATFORMS := miyoomini my282 rg35xxplus tg5040

MINUI_LIST_VERSION := 0.7.0
MINUI_PRESENTER_VERSION := 0.4.0
JQ_VERSION := 1.7.1

clean:
	rm -f bin/*/minui-list || true
	rm -f bin/*/minui-presenter || true
	rm -f bin/*/jq || true

bump-version:
	jq '.version = "$(RELEASE_VERSION)"' pak.json > pak.json.tmp
	mv pak.json.tmp pak.json

build: $(foreach platform,$(PLATFORMS),bin/$(platform)/minui-list bin/$(platform)/minui-presenter)  $(foreach arch,$(ARCHITECTURES),bin/$(arch)/jq)

bin/%/minui-list:
	mkdir -p bin/$*
	curl -f -o bin/$*/minui-list -sSL https://github.com/josegonzalez/minui-list/releases/download/$(MINUI_LIST_VERSION)/minui-list-$*
	chmod +x bin/$*/minui-list

bin/%/minui-presenter:
	mkdir -p bin/$*
	curl -f -o bin/$*/minui-presenter -sSL https://github.com/josegonzalez/minui-presenter/releases/download/$(MINUI_PRESENTER_VERSION)/minui-presenter-$*
	chmod +x bin/$*/minui-presenter

bin/arm/jq:
	mkdir -p bin/arm
	curl -f -o bin/arm/jq -sSL https://github.com/jqlang/jq/releases/download/jq-$(JQ_VERSION)/jq-linux-armhf
	curl -sSL -o bin/arm/jq.LICENSE "https://raw.githubusercontent.com/jqlang/jq/refs/heads/$(JQ_VERSION)/COPYING"

bin/arm64/jq:
	mkdir -p bin/arm64
	curl -f -o bin/arm64/jq -sSL https://github.com/jqlang/jq/releases/download/jq-$(JQ_VERSION)/jq-linux-arm64
	curl -sSL -o bin/arm64/jq.LICENSE "https://raw.githubusercontent.com/jqlang/jq/refs/heads/$(JQ_VERSION)/COPYING"

release: build
	mkdir -p dist
	git archive --format=zip --output "dist/$(PAK_NAME).pak.zip" HEAD
	while IFS= read -r file; do zip -r "dist/$(PAK_NAME).pak.zip" "$$file"; done < .gitarchiveinclude
	ls -lah dist
