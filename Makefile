# --- CONFIG ---
VERSION := 1.0.0
ZARF_VERSION := v0.67.0
ARCH := amd64

# Default to your ECR
REGISTRY ?= 973213517498.dkr.ecr.us-east-2.amazonaws.com/airgap-ai-testing/flora
# SUGGESTION: Use AWS ECR Public for public distribution (e.g. public.ecr.aws/your-alias/flora)
# REGISTRY ?= public.ecr.aws/973213517498/flora
SRC_REGISTRY ?= $(REGISTRY)

# Explicitly define overrides
OVERRIDES := --registry-override docker.io=$(REGISTRY) \
             --registry-override quay.io=$(REGISTRY) \
             --registry-override registry.k8s.io=$(REGISTRY) \
             --registry-override ghcr.io=$(REGISTRY) \
             --registry-override registry.gitlab.com=$(REGISTRY)

# --- TARGETS ---
.PHONY: all prep build-cli release-oci clean build-site

all: build-cli build-site

prep:
	@mkdir -p cli/embedded
	@# Check if Zarf binary exists, download if not. Fail if download fails.
	@if [ ! -f cli/embedded/zarf ]; then \
		echo "⬇️ Downloading Zarf CLI..."; \
		curl -fL "https://github.com/zarf-dev/zarf/releases/download/$(ZARF_VERSION)/zarf_$(ZARF_VERSION)_Linux_amd64" -o cli/embedded/zarf || (rm -f cli/embedded/zarf && exit 1); \
		chmod +x cli/embedded/zarf; \
	fi
	@# Check if Init package exists, download if not. Fail if download fails.
	@if [ ! -f zarf-init-$(ARCH)-$(ZARF_VERSION).tar.zst ]; then \
		echo "⬇️ Downloading Zarf Init Package..."; \
		curl -fL "https://github.com/zarf-dev/zarf/releases/download/$(ZARF_VERSION)/zarf-init-$(ARCH)-$(ZARF_VERSION).tar.zst" -o zarf-init-$(ARCH)-$(ZARF_VERSION).tar.zst || (rm -f zarf-init-$(ARCH)-$(ZARF_VERSION).tar.zst && exit 1); \
	fi

build-cli: prep
	@echo "🔨 Building Staq CLI..."
ifdef CI
	go mod tidy
	go build -ldflags="-X 'main.Version=$(VERSION)' -X 'main.Registry=$(REGISTRY)'" -o staq ./cli
else
	@docker run --rm \
	-v "$(PWD)":/go/src/app \
	-w /go/src/app \
	golang:1.23 \
	bash -c "go mod tidy && go build -ldflags=\"-X 'main.Version=$(VERSION)' -X 'main.Registry=$(REGISTRY)'\" -o staq ./cli"
endif

build-site:
	@echo "📚 Building Documentation Site..."
	@if [ -d "docs" ]; then \
		cd docs && npm install && npm run build; \
	else \
		echo "⚠️  No 'docs' directory found. Run 'npx create-docusaurus@latest docs classic' to start."; \
	fi

release-oci: build-cli
	@echo "🚀 Streaming Packages to $(REGISTRY)..."
	@mkdir -p dist/platformstaq-v$(VERSION)

	# 1. CORE
	@echo "📦 [1/5] Building Core..."
	zarf package create packages/01-staq-core --confirm --skip-sbom -l warn  \
		--set PACKAGE_VERSION=$(VERSION) --set CI_REGISTRY_IMAGE=$(REGISTRY) \
		$(OVERRIDES) \
		--output oci://$(REGISTRY)

	# 2. GITLAB
	@echo "📦 [2/5] Building GitLab..."
	zarf package create packages/02a-staq-gitlab --confirm --skip-sbom -l warn \
		--set PACKAGE_VERSION=$(VERSION) --set CI_REGISTRY_IMAGE=$(REGISTRY) \
		$(OVERRIDES) \
		--output oci://$(REGISTRY)

	# 3. FACTORY
	@echo "📦 [3/5] Building Factory Tools..."
	zarf package create packages/02b-staq-factory --confirm --skip-sbom -l warn \
		--set PACKAGE_VERSION=$(VERSION) --set CI_REGISTRY_IMAGE=$(REGISTRY) \
		$(OVERRIDES) \
		--output oci://$(REGISTRY)

	# 4. IDE
	@echo "📦 [4/5] Building IDE..."
	zarf package create packages/03-staq-ide --confirm --skip-sbom -l warn \
		--set PACKAGE_VERSION=$(VERSION) --set CI_REGISTRY_IMAGE=$(REGISTRY) \
		$(OVERRIDES) \
		--output oci://$(REGISTRY)

	# 5. INIT PACKAGE
	@echo "📦 [5/5] Publishing Init Package..."
	zarf package publish zarf-init-$(ARCH)-$(ZARF_VERSION).tar.zst oci://$(REGISTRY)

	# 6. CLI
	@echo "📤 Uploading CLI binary..."
	@cp staq dist/platformstaq-v$(VERSION)/
	@curl --fail --header "JOB-TOKEN: $(CI_JOB_TOKEN)" \
		--upload-file dist/platformstaq-v$(VERSION)/staq \
		"$(CI_API_V4_URL)/projects/$(CI_PROJECT_ID)/packages/generic/platformstaq/$(VERSION)/staq-linux-amd64"

clean:
	rm -rf dist/ zarf-package-*.tar.zst staq