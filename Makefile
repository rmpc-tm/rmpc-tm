PLUGIN_NAME = RandomMapPaceChallenge
FILE = build/$(PLUGIN_NAME)$(if $(VERSION),-$(VERSION)).op

.PHONY: all
all: package

.PHONY: package
package:
	mkdir -p build
	@echo "Packaging $(FILE)"
	zip -r $(FILE) info.toml LICENSE src/*
