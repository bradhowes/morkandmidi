SCHEME = -scheme MorkAndMIDI-Package

DEST_IOS = -destination platform="iOS Simulator,name=iPhone 11"
DEST_MACOS = -destination platform=macOS

RESULT_BUNDLE_IOS = ./coverage_ios
RESULT_BUNDLE_MACOS = ./coverage_macos

default: coverage

build: clean
	xcodebuild build $(SCHEME) $(DEST_IOS)
	xcodebuild build $(SCHEME) $(DEST_MACOS)

TEST_FLAGS_IOS = -enableCodeCoverage YES ENABLE_TESTING_SEARCH_PATHS=YES -resultBundlePath $(RESULT_BUNDLE_IOS)
TEST_FLAGS_MACOS = -enableCodeCoverage YES ENABLE_TESTING_SEARCH_PATHS=YES -resultBundlePath $(RESULT_BUNDLE_MACOS)

test: build
	xcodebuild test $(SCHEME) $(DEST_IOS) $(TEST_FLAGS_IOS)
	xcodebuild test $(SCHEME) $(DEST_MACOS) $(TEST_FLAGS_MACOS)

# Extract coverage info for SoundFonts -- expects defintion of env variable GITHUB_ENV

ios_cov.txt: test
	xcrun xccov view --report --only-targets $(RESULT_BUNDLE_IOS).xcresult > ios_cov.txt
	@cat ios_cov.txt

macos_cov.txt: test
	xcrun xccov view --report --only-targets $(RESULT_BUNDLE_MACOS).xcresult > macos_cov.txt
	@cat macos_cov.txt

ios_percentage.txt: ios_cov.txt
	@awk '/MorkAndMIDI.framework/ {print $$4}' < ios_cov.txt > ios_percentage.txt
	@echo "iOS: $$(< ios_percentage.txt)"

macos_percentage.txt: macos_cov.txt
	@awk '/MorkAndMIDI.framework/ {print $$4}' < macos_cov.txt > macos_percentage.txt
	@echo "macOS: $$(< macos_percentage.txt)"

coverage: ios_percentage.txt macos_percentage.txt
	@if [[ -n "$$GITHUB_ENV" ]]; then \
		echo "PERCENTAGE=$$(< ios_percentage.txt)" >> $$GITHUB_ENV; \
	fi

clean:
	rm -rf ios_cov.txt ios_percentage.txt macos_cov.txt macos_percentage.txt \
		$(RESULT_BUNDLE_IOS) $(RESULT_BUNDLE_IOS).xcresult \
		$(RESULT_BUNDLE_MACOS) $(RESULT_BUNDLE_MACOS).xcresult
	xcodebuild clean $(SCHEME) $(DEST_IOS)
	xcodebuild clean $(SCHEME) $(DEST_MACOS)

.PHONY: build test coverage clean
