PLATFORM_IOS = iOS Simulator,name=iPhone 11
PLATFORM_MACOS = macOS

SCHEME = -scheme MorkAndMIDI-Package
DEST = -destination platform="$(PLATFORM_IOS)"
RESULT_BUNDLE = ./coverage

default: coverage

build: clean
	xcodebuild build $(SCHEME) $(DEST)

TEST_FLAGS = -enableCodeCoverage YES ENABLE_TESTING_SEARCH_PATHS=YES -resultBundlePath $(RESULT_BUNDLE)

test: build
	xcodebuild test $(SCHEME) $(DEST) $(TEST_FLAGS)

# Extract coverage info for SoundFonts -- expects defintion of env variable GITHUB_ENV

cov.txt: test
	xcrun xccov view --report --only-targets $(RESULT_BUNDLE).xcresult > cov.txt
	@cat cov.txt

percentage.txt: cov.txt
	awk '/MorkAndMIDI.framework/ {print $$4}' < cov.txt > percentage.txt
	@cat percentage.txt

coverage: percentage.txt
	@if [[ -n "$$GITHUB_ENV" ]]; then \
		echo "PERCENTAGE=$$(< percentage.txt)" >> $$GITHUB_ENV; \
	fi

clean:
	@echo "-- removing cov.txt percentage.txt"
	@-rm -rf cov.txt percentage.txt $(RESULT_BUNDLE) $(RESULT_BUNDLE).xcresult
	xcodebuild clean $(SCHEME) $(DEST)

.PHONY: build test coverage clean
