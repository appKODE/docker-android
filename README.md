# Unified Android SDK Docker Builds

This repository uses one branch and one parameterized `Dockerfile`.
All image variants are defined in `variants.json` and released by Git tag.

## Existing Variants And Differences

| Variant ID | Ubuntu | Platforms | Java default | Android APIs | NDK / CMake | Extra features |
| --- | --- | --- | --- | --- | --- | --- |
| `api33-34-j11-17` | `23.04` | `linux/amd64` | `java-1.17.0-openjdk-amd64` | `33,34` | `-` | `-` |
| `api33-34-j17-21` | `23.04` | `linux/amd64` | `java-1.21.0-openjdk-amd64` | `33,34` | `-` | `-` |
| `api33-34-j11-17-u25-ma` | `25.04` | `linux/amd64,linux/arm64` | `java-1.17.0-openjdk-amd64` | `33,34` | `-` | `multi-arch` |
| `api33-34-j11-17-profiler` | `23.04` | `linux/amd64` | `java-1.17.0-openjdk-amd64` | `33,34` | `-` | `gradle-profiler` |
| `api34-35-j23-openjdk` | `23.04` | `linux/amd64` | `java-1.23.0-openjdk-amd64` | `34,35` | `-` | `-` |
| `api34-35-j17-21-23-ndk26` | `23.04` | `linux/amd64` | `java-23-amazon-corretto` | `34,35` | `ndk 26.2.11394342`, `cmake 3.18.1/3.22.1` | `python2` |
| `api34-35-j17-21-23-ndk26-emu-api35` | `23.04` | `linux/amd64` | `java-23-amazon-corretto` | `34,35` (+ `system-image 35`) | `ndk 26.2.11394342`, `cmake 3.18.1/3.22.1` | `python2`, `emulator`, `marathon 0.10.1` |
| `api34-35-j17-23` | `23.04` | `linux/amd64` | `java-23-amazon-corretto` | `34,35` | `-` | `-` |
| `api34-35-j17-23-ndk26` | `23.04` | `linux/amd64` | `java-23-amazon-corretto` | `34,35` | `ndk 26.2.11394342`, `cmake 3.18.1/3.22.1` | `python2` |
| `api34-35-j23-corretto` | `23.04` | `linux/amd64` | `java-23-amazon-corretto` | `34,35` | `-` | `-` |
| `api35-36-j17-23` | `23.04` | `linux/amd64` | `java-23-amazon-corretto` | `35,36` | `-` | `-` |
| `api35-36-j17-23-ndk29-u24-gcc14` | `24.04` | `linux/amd64` | `java-23-amazon-corretto` | `35,36` | `ndk 29.0.14033849`, `cmake 4.1.1` | `python2`, `gcc14` |
| `api35-36-j17-21-23-ndk26-emu-api35` | `23.04` | `linux/amd64` | `java-23-amazon-corretto` | `35,36` (+ `system-image 35`) | `ndk 26.2.11394342`, `cmake 3.18.1/3.22.1` | `python2`, `emulator`, `marathon 0.10.1` |
| `api36-37-j17-21-23` | `23.04` | `linux/amd64` | `java-23-amazon-corretto` | `36,37` | `-` | `-` |
| `api36-37-j17-21-23-ndk26-emu-api36` | `23.04` | `linux/amd64` | `java-23-amazon-corretto` | `36,37` (+ `system-image 36`) | `ndk 26.2.11394342`, `cmake 3.18.1/3.22.1` | `python2`, `emulator`, `marathon 0.10.1` |
| `api37-j17-21-23` | `23.04` | `linux/amd64` | `java-23-amazon-corretto` | `37` | `-` | `-` |

## Release By Git Tag

Push a Git tag in this format:

```bash
build/<variant_id>/vN
```

Example:

```bash
git tag build/api34-35-j17-23-ndk26/v5
git push origin build/api34-35-j17-23-ndk26/v5
```

This triggers `.github/workflows/publish-by-tag.yml` and publishes:

- `DOCKER_HUB_USERNAME/android-sdk:<variant_id>`
- `DOCKER_HUB_USERNAME/android-sdk:<variant_id>-vN`

## Manual Release For Missing Variants

Use `.github/workflows/release-all-missing.yml` (`workflow_dispatch`) with inputs:

- `release`: `vN`
- `dry_run`: `true` or `false`
- `max_parallel`: parallel build limit

Behavior:

- Checks each variant for `android-sdk:<variant_id>-vN`
- Skips existing tags
- Builds only missing variants
- Pushes only when `dry_run=false`

## Tools And Licenses

- `tools/` now supports built-in mode only (legacy `lazy-dl` flow removed).
- Removed outdated legacy package lists and unused emulator wait script.
- `licenses/` is kept and copied into images to preserve non-interactive SDK license acceptance.
- `/opt/tools/entrypoint.sh` initializes SDK state at container start.
- `/opt/tools/android-sdk-update.sh` bootstraps commandline tools, updates SDK metadata, and accepts licenses.
- `/opt/tools/android-env.sh` exports Android env vars and provides `update_sdk` / `andep`.
- `/opt/tools/android-accept-licenses.sh` is an `expect` wrapper that auto-confirms SDK license prompts.

### Runtime Usage In Container

```bash
source /opt/android-sdk-linux/bin/android-env.sh
sdkmanager --list
andep "platforms;android-36"
update_sdk
```

## Java Switching (Variants With Multiple Installed JDKs)

Use this to see available Java alternatives in a container:

```bash
update-java-alternatives --list
```

Use this to switch active system Java:

```bash
update-java-alternatives --set <alternative_name>
java -version
```

If you run as a non-root user, switch Java for the current shell with:

```bash
export JAVA_HOME=<path_to_jvm>
export PATH="${JAVA_HOME}/bin:${PATH}"
java -version
```

Multi-JDK variants:

| Variant ID | Installed Java packages | Default Java | Example switches |
| --- | --- | --- | --- |
| `api33-34-j11-17` | `openjdk-11-jdk`, `openjdk-17-jdk` | `java-1.17.0-openjdk-amd64` | `update-java-alternatives --set java-1.11.0-openjdk-amd64` |
| `api33-34-j17-21` | `openjdk-17-jdk`, `openjdk-21-jdk` | `java-1.21.0-openjdk-amd64` | `update-java-alternatives --set java-1.17.0-openjdk-amd64` |
| `api33-34-j11-17-u25-ma` | `openjdk-11-jdk`, `openjdk-17-jdk` | `java-1.17.0-openjdk-amd64` | `update-java-alternatives --set java-1.11.0-openjdk-amd64` |
| `api33-34-j11-17-profiler` | `openjdk-11-jdk`, `openjdk-17-jdk` | `java-1.17.0-openjdk-amd64` | `update-java-alternatives --set java-1.11.0-openjdk-amd64` |
| `api34-35-j17-21-23-ndk26` | `openjdk-17-jdk`, `java-21-amazon-corretto-jdk`, `java-23-amazon-corretto-jdk` | `java-23-amazon-corretto` | `update-java-alternatives --set java-21-amazon-corretto`, `update-java-alternatives --set java-1.17.0-openjdk-amd64` |
| `api34-35-j17-21-23-ndk26-emu-api35` | `openjdk-17-jdk`, `java-21-amazon-corretto-jdk`, `java-23-amazon-corretto-jdk` | `java-23-amazon-corretto` | `update-java-alternatives --set java-21-amazon-corretto`, `update-java-alternatives --set java-1.17.0-openjdk-amd64` |
| `api34-35-j17-23` | `openjdk-17-jdk`, `java-23-amazon-corretto-jdk` | `java-23-amazon-corretto` | `update-java-alternatives --set java-1.17.0-openjdk-amd64` |
| `api34-35-j17-23-ndk26` | `openjdk-17-jdk`, `java-23-amazon-corretto-jdk` | `java-23-amazon-corretto` | `update-java-alternatives --set java-1.17.0-openjdk-amd64` |
| `api35-36-j17-23` | `openjdk-17-jdk`, `java-23-amazon-corretto-jdk` | `java-23-amazon-corretto` | `update-java-alternatives --set java-1.17.0-openjdk-amd64` |
| `api35-36-j17-23-ndk29-u24-gcc14` | `openjdk-17-jdk`, `java-23-amazon-corretto-jdk` | `java-23-amazon-corretto` | `update-java-alternatives --set java-1.17.0-openjdk-amd64` |
| `api35-36-j17-21-23-ndk26-emu-api35` | `openjdk-17-jdk`, `java-21-amazon-corretto-jdk`, `java-23-amazon-corretto-jdk` | `java-23-amazon-corretto` | `update-java-alternatives --set java-21-amazon-corretto`, `update-java-alternatives --set java-1.17.0-openjdk-amd64` |
| `api36-37-j17-21-23` | `openjdk-17-jdk`, `java-21-amazon-corretto-jdk`, `java-23-amazon-corretto-jdk` | `java-23-amazon-corretto` | `update-java-alternatives --set java-21-amazon-corretto`, `update-java-alternatives --set java-1.17.0-openjdk-amd64` |
| `api36-37-j17-21-23-ndk26-emu-api36` | `openjdk-17-jdk`, `java-21-amazon-corretto-jdk`, `java-23-amazon-corretto-jdk` | `java-23-amazon-corretto` | `update-java-alternatives --set java-21-amazon-corretto`, `update-java-alternatives --set java-1.17.0-openjdk-amd64` |
| `api37-j17-21-23` | `openjdk-17-jdk`, `java-21-amazon-corretto-jdk`, `java-23-amazon-corretto-jdk` | `java-23-amazon-corretto` | `update-java-alternatives --set java-21-amazon-corretto`, `update-java-alternatives --set java-1.17.0-openjdk-amd64` |

## Local Validation

```bash
./scripts/validate-variants.sh

for id in $(jq -r '.variants | keys[]' variants.json); do
  ./scripts/parse-build-tag.sh "build/${id}/v9999" >/dev/null
  ./scripts/resolve-variant.sh --variant-id "${id}" --release v9999 --docker-user example >/dev/null
done
```

## Files

- `variants.json`: variant source of truth
- `Dockerfile`: parameterized build template
- `tools/`: bootstrap and SDK helper scripts used inside image build/runtime
- `licenses/`: Android SDK license hashes copied into the image
- `scripts/parse-build-tag.sh`: validates/parses `build/<variant_id>/vN`
- `scripts/resolve-variant.sh`: resolves build args + output tags from `variants.json`
- `scripts/list-missing-for-release.sh`: finds variants missing `-vN` image tags
- `scripts/validate-variants.sh`: schema/content validation
- `.github/workflows/publish-by-tag.yml`: release by Git tag
- `.github/workflows/release-all-missing.yml`: manual release missing variants only
- `.github/workflows/validate-config.yml`: CI config validation
