#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  resolve-variant.sh --variant-id <id> --release <vN> [--docker-user <user>] [--variants-file <path>] [--output <path>]
USAGE
}

variant_id=""
release=""
docker_user="${DOCKER_USER:-}"
variants_file="${VARIANTS_FILE:-variants.json}"
output_file="${GITHUB_OUTPUT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --variant-id)
      variant_id="$2"
      shift 2
      ;;
    --release)
      release="$2"
      shift 2
      ;;
    --docker-user)
      docker_user="$2"
      shift 2
      ;;
    --variants-file)
      variants_file="$2"
      shift 2
      ;;
    --output)
      output_file="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${variant_id}" || -z "${release}" ]]; then
  usage
  exit 1
fi

if [[ ! "${release}" =~ ^v[0-9]+$ ]]; then
  echo "Invalid release format: ${release} (expected vN)" >&2
  exit 1
fi

if [[ -z "${docker_user}" ]]; then
  docker_user="example"
fi

if [[ ! -f "${variants_file}" ]]; then
  echo "Variants file not found: ${variants_file}" >&2
  exit 1
fi

variant_json="$(jq -ce --arg id "${variant_id}" '.variants[$id]' "${variants_file}")" || {
  echo "Variant not found: ${variant_id}" >&2
  exit 1
}

image_repo="$(jq -r '.image_repo' "${variants_file}")"
platforms="$(jq -r '.platforms | join(",")' <<<"${variant_json}")"
ubuntu_version="$(jq -r '.docker.ubuntu' <<<"${variant_json}")"
apt_profile="$(jq -r '.docker.apt_profile' <<<"${variant_json}")"
apt_packages_csv="$(jq -r '.docker.apt_packages | join(",")' <<<"${variant_json}")"
java_default="$(jq -r '.docker.java_default' <<<"${variant_json}")"
sdk_packages_csv="$(jq -r '.docker.sdk_packages | join(",")' <<<"${variant_json}")"
enable_profiler="$(jq -r '.docker.features.profiler' <<<"${variant_json}")"
enable_python2="$(jq -r '.docker.features.python2' <<<"${variant_json}")"
enable_gcc14="$(jq -r '.docker.features.gcc14' <<<"${variant_json}")"
enable_emulator="$(jq -r '.docker.features.emulator // false' <<<"${variant_json}")"
enable_marathon="$(jq -r '.docker.features.marathon // false' <<<"${variant_json}")"
marathon_version="$(jq -r '.docker.marathon_version // ""' <<<"${variant_json}")"
enable_allure="$(jq -r '.docker.features.allure // false' <<<"${variant_json}")"
allure_version="$(jq -r '.docker.allure_version // ""' <<<"${variant_json}")"

canonical_tag="${docker_user}/${image_repo}:${variant_id}"
release_tag="${docker_user}/${image_repo}:${variant_id}-${release}"

if [[ -n "${output_file}" ]]; then
  {
    echo "variant_id=${variant_id}"
    echo "release=${release}"
    echo "image_repo=${image_repo}"
    echo "platforms=${platforms}"
    echo "ubuntu_version=${ubuntu_version}"
    echo "apt_profile=${apt_profile}"
    echo "apt_packages_csv=${apt_packages_csv}"
    echo "java_default=${java_default}"
    echo "sdk_packages_csv=${sdk_packages_csv}"
    echo "enable_profiler=${enable_profiler}"
    echo "enable_python2=${enable_python2}"
    echo "enable_gcc14=${enable_gcc14}"
    echo "enable_emulator=${enable_emulator}"
    echo "enable_marathon=${enable_marathon}"
    echo "marathon_version=${marathon_version}"
    echo "enable_allure=${enable_allure}"
    echo "allure_version=${allure_version}"
    echo "canonical_tag=${canonical_tag}"
    echo "release_tag=${release_tag}"
    echo "tags<<EOF"
    echo "${canonical_tag}"
    echo "${release_tag}"
    echo "EOF"
  } >>"${output_file}"
else
  cat <<OUT
variant_id=${variant_id}
release=${release}
image_repo=${image_repo}
platforms=${platforms}
ubuntu_version=${ubuntu_version}
apt_profile=${apt_profile}
apt_packages_csv=${apt_packages_csv}
java_default=${java_default}
sdk_packages_csv=${sdk_packages_csv}
enable_profiler=${enable_profiler}
enable_python2=${enable_python2}
enable_gcc14=${enable_gcc14}
enable_emulator=${enable_emulator}
enable_marathon=${enable_marathon}
marathon_version=${marathon_version}
enable_allure=${enable_allure}
allure_version=${allure_version}
canonical_tag=${canonical_tag}
release_tag=${release_tag}
OUT
fi
