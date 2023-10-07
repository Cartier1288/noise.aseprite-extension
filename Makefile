all:

package:
	zip -r noise.aseprite-extension "./noise-plugin.lua" "./package.json" \
		"./scripts" "./bin"
