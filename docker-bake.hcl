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
  result =  ["type=registry,oci-mediatypes=true,mode=max,compression=estargz,compression-level=5,ref=${REPOSITORY}/cache:${image}-${TAG}-${arch}"]
}

# No default target is specified.
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
  context = "imagemagick"
  contexts = {
    # The digest (sha256 hash) is not platform specific but the digest for the manifest of all platforms.
    # It will be the digest printed when you do: docker pull alpine:3.17.1
    # Not the one displayed on DockerHub.
    # N.B. This should match the value used in <https://github.com/Islandora-Devops/isle-buildkit>
    alpine = "docker-image://alpine:3.18.4@sha256:eece025e432126ce23f223450a0326fbebde39cdf496a85d8c016293fc851978"
  }
}

target "imagemagick-amd64" {
  inherits = ["imagemagick-common"]
  tags = tags("imagemagick", "amd64")
  cache-from = cacheFrom("imagemagick", "amd64")
  platforms = ["linux/amd64"]
}

target "imagemagick-amd64-ci" {
  inherits = ["imagemagick-amd64"]
  cache-to = cacheTo("imagemagick", "amd64")
}

target "imagemagick-arm64" {
  inherits = ["imagemagick-common"]
  tags = tags("imagemagick", "arm64")
  cache-from = cacheFrom("imagemagick", "arm64")
  platforms = ["linux/arm64"]
}

target "imagemagick-arm64-ci" {
  inherits = ["imagemagick-arm64"]
  cache-to = cacheTo("imagemagick", "arm64")
}