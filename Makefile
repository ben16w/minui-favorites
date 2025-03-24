TAG ?= latest
PAK_NAME := $(shell jq -r .label config.json)

ARCHITECTURES := arm arm64
PLATFORMS := miyoomini my282 rg35xxplus tg5040

MINUI_LIST_VERSION := 0.7.0
MINUI_PRESENTER_VERSION := 0.4.0

clean:
	rm -f bin/*/minui-list || true
	rm -f bin/*/minui-presenter || true

build: $(foreach platform,$(PLATFORMS),bin/$(platform)/minui-list bin/$(platform)/minui-presenter)

bin/%/minui-list:
	mkdir -p bin/$*
	curl -f -o bin/$*/minui-list -sSL https://github.com/josegonzalez/minui-list/releases/download/$(MINUI_LIST_VERSION)/minui-list-$*
	chmod +x bin/$*/minui-list

bin/%/minui-presenter:
	mkdir -p bin/$*
	curl -f -o bin/$*/minui-presenter -sSL https://github.com/josegonzalez/minui-presenter/releases/download/$(MINUI_PRESENTER_VERSION)/minui-presenter-$*
	chmod +x bin/$*/minui-presenter

release: build
	mkdir -p dist
	git archive --format=zip --output "dist/$(PAK_NAME).pak.zip" HEAD
	while IFS= read -r file; do zip -r "dist/$(PAK_NAME).pak.zip" "$$file"; done < .gitarchiveinclude
	ls -lah dist
