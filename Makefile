.PHONY: cli desktop

cli:
	nim c -d:release --out:bluecoder cli/src/bluecoder.nim

desktop:
	cd ui && npm install && npm run tauri build
