#!/usr/bin/env bash
set -euo pipefail

variants_file="${1:-variants.json}"

if [[ ! -f "${variants_file}" ]]; then
  echo "Variants file not found: ${variants_file}" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

expected_ids_json='[
  "api33-34-j11-17",
  "api33-34-j11-17-profiler",
  "api33-34-j11-17-u25-ma",
  "api33-34-j17-21",
  "api34-35-j17-21-23-ndk26",
  "api34-35-j17-21-23-ndk26-emu-api35",
  "api34-35-j17-23",
  "api34-35-j17-23-ndk26",
  "api34-35-j23-corretto",
  "api34-35-j23-openjdk",
  "api35-36-j17-21-23-ndk26-emu-api35",
  "api35-36-j17-23",
  "api35-36-j17-23-ndk29-u24-gcc14"
]'

jq -e '.image_repo | type == "string" and length > 0' "${variants_file}" >/dev/null
jq -e '.variants | type == "object" and length > 0' "${variants_file}" >/dev/null
jq -e --argjson expected_ids "${expected_ids_json}" '
  (.variants | keys | sort) == ($expected_ids | sort)
' "${variants_file}" >/dev/null

jq -e '
  .variants
  | to_entries
  | all(
      (.key | test("^[a-z0-9][a-z0-9-]*$"))
      and (.value.platforms | type == "array" and length > 0 and all(test("^linux/(amd64|arm64)$")))
      and (.value.docker.ubuntu | type == "string" and test("^[0-9]+\\.[0-9]+$"))
      and (.value.docker.apt_profile | IN("ubuntu23_old_releases", "ubuntu25_i386_focal", "ubuntu24_toolchain"))
      and (.value.docker.apt_packages | type == "array" and length > 0 and length == (unique | length) and all(type == "string" and length > 0 and (contains(",") | not)))
      and (.value.docker.java_default | type == "string" and length > 0)
      and (.value.docker.sdk_packages | type == "array" and length > 0 and length == (unique | length) and all(type == "string" and length > 0 and (contains(",") | not)))
      and (.value.docker.features | type == "object")
      and (.value.docker.features.profiler | type == "boolean")
      and (.value.docker.features.python2 | type == "boolean")
      and (.value.docker.features.gcc14 | type == "boolean")
      and (.value.docker.features.emulator | type == "boolean")
      and (.value.docker.features.marathon | type == "boolean")
      and (
        if .value.docker.features.marathon
        then (.value.docker.marathon_version | type == "string" and test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
        else ((.value.docker | has("marathon_version")) | not)
        end
      )
      and (.value.docker.features.allure | type == "boolean")
      and (
        if .value.docker.features.allure
        then (.value.docker.allure_version | type == "string" and test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
        else ((.value.docker | has("allure_version")) | not)
        end
      )
    )
' "${variants_file}" >/dev/null

echo "Variants configuration is valid: ${variants_file}"
