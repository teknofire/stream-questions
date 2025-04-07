VERSION := $(file < VERSION)
SAFE_VERSION := $(VERSION:.=_)
RELEASE := StreamQuestions_v$(SAFE_VERSION).zip
BUILDS_PATH := builds

clean:
	rm $(BUILDS_PATH)/StreamQuestions_v*.zip || true

release: clean
	cp README.md $(BUILDS_PATH)
	cd $(BUILDS_PATH) && zip $(RELEASE) *
