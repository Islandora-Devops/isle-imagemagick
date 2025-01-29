variable "SOURCE_DATE_EPOCH" {
  default = "0"
}

variable "REPOSITORY" {
  default = "islandora"
}

variable "TAG" {
  # "local" is to distinguish remote images from those produced locally.
  default = "local"
}

###############################################################################
# Functions
###############################################################################
function hostArch {
  params = []
  result = equal("linux/amd64", BAKE_LOCAL_PLATFORM) ? "amd64" : "arm64" # Only two platforms supported.
}

function "tags" {
  params = [image, arch]
  result = ["${REPOSITORY}/${image}:${TAG}-${arch}"]
}

function "cacheFrom" {
  params = [image, arch]
  result = ["type=registry,ref=${REPOSITORY}/cache:${image}-main-${arch}", "type=registry,ref=${REPOSITORY}/cache:${image}-${TAG}-${arch}"]
}

function "cacheTo" {
  params = [image, arch]
  result = ["type=registry,oci-mediatypes=true,mode=max,compression=estargz,compression-level=5,ref=${REPOSITORY}/cache:${image}-${TAG}-${arch}"]
}

###############################################################################
# Groups
###############################################################################
group "default" {
  targets = [
    "imagemagick",
  ]
}

group "amd64" {
  targets = [
    "imagemagick-amd64",
  ]
}

group "arm64" {
  targets = [
    "imagemagick-arm64",
  ]
}

# CI should build both and push to the remote cache.
group "ci" {
  targets = [
    "imagemagick-amd64-ci",
    "imagemagick-arm64-ci",
  ]
}

###############################################################################
# Targets
###############################################################################
target "common" {
  args = {
    # Required for reproduciable builds.
    # Requires Buildkit 0.11+
    # See: https://reproducible-builds.org/docs/source-date-epoch/
    SOURCE_DATE_EPOCH = "${SOURCE_DATE_EPOCH}",
  }
}

target "imagemagick-common" {
  inherits = ["common"]
  context  = "imagemagick"
  contexts = {
    # The digest (sha256 hash) is not platform specific but the digest for the manifest of all platforms.
    # It will be the digest printed when you do: docker pull alpine:3.17.1
    # Not the one displayed on DockerHub.
    # N.B. This should match the value used in <https://github.com/Islandora-Devops/isle-buildkit>
    alpine = "docker-image://alpine:3.21.2@sha256:56fa17d2a7e7f168a043a2712e63aed1f8543aeafdcee47c58dcffe38ed51099"
  }
}

target "imagemagick-amd64" {
  inherits   = ["imagemagick-common"]
  tags       = tags("imagemagick", "amd64")
  cache-from = cacheFrom("imagemagick", "amd64")
  platforms  = ["linux/amd64"]
}

target "imagemagick-amd64-ci" {
  inherits = ["imagemagick-amd64"]
  cache-to = cacheTo("imagemagick", "amd64")
}

target "imagemagick-arm64" {
  inherits   = ["imagemagick-common"]
  tags       = tags("imagemagick", "arm64")
  cache-from = cacheFrom("imagemagick", "arm64")
  platforms  = ["linux/arm64"]
}

target "imagemagick-arm64-ci" {
  inherits = ["imagemagick-arm64"]
  cache-to = cacheTo("imagemagick", "arm64")
}

target "imagemagick" {
  inherits   = ["imagemagick-common"]
  cache-from = cacheFrom("imagemagick", hostArch())
  tags       = tags("imagemagick", "")
}
