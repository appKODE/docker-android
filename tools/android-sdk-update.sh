#!/usr/bin/env bash
set -euo pipefail

mode="${1:-built-in}"
if [[ "${mode}" != "built-in" ]]; then
  echo "Only 'built-in' mode is supported" >&2
  exit 1
fi

mkdir -p /opt/android-sdk-linux/bin/
cp /opt/tools/android-env.sh /opt/android-sdk-linux/bin/
source /opt/android-sdk-linux/bin/android-env.sh

cd "${ANDROID_HOME}"
echo "Set ANDROID_HOME to ${ANDROID_HOME}"

if [[ -f commandlinetools-linux.zip ]]; then
  echo "SDK Tools already bootstrapped. Skipping initial setup"
else
  echo "Bootstrapping SDK-Tools"
  # cmdline-tools must be recent enough to read repository2-3.xml, where newer
  # platforms (e.g. platforms;android-37.0, android-36.1) are published. The old
  # 6609375 (v3.0, 2020) only understood repository2-1/2-2.xml, which stop at
  # platforms;android-36, so android-37 failed with "Failed to find package".
  wget -q https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip -O commandlinetools-linux.zip
  # Modern zips extract to ./cmdline-tools/{bin,lib}; nest under cmdline-tools/tools
  # to keep the layout the Dockerfile and PATH entries expect.
  rm -rf cmdline-tools-tmp
  unzip -q commandlinetools-linux.zip -d cmdline-tools-tmp
  mkdir -p cmdline-tools
  mv cmdline-tools-tmp/cmdline-tools cmdline-tools/tools
  rm -rf cmdline-tools-tmp commandlinetools-linux.zip
fi

echo "Ensuring repositories.cfg exists"
mkdir -p ~/.android/
touch ~/.android/repositories.cfg

echo "Copying licenses"
cp -rv /opt/licenses "${ANDROID_HOME}/licenses"

echo "Copying tools"
mkdir -p "${ANDROID_HOME}/bin"
cp -v /opt/tools/*.sh "${ANDROID_HOME}/bin"

echo "Updating SDK metadata"
update_sdk

echo "Accepting SDK licenses"
android-accept-licenses.sh "sdkmanager --licenses --verbose"
