ARG UBUNTU_VERSION=23.04
FROM ubuntu:${UBUNTU_VERSION}

ARG APT_PROFILE=ubuntu23_old_releases
ARG APT_PACKAGES_CSV
ARG JAVA_DEFAULT
ARG SDK_PACKAGES_CSV
ARG ENABLE_PROFILER=false
ARG ENABLE_PYTHON2=false
ARG ENABLE_GCC14=false
ARG ENABLE_EMULATOR=false
ARG ENABLE_MARATHON=false
ARG MARATHON_VERSION=0.10.1
ARG ENABLE_ALLURE=false
ARG ALLURE_VERSION=2.27.0
ARG PYTHON_VERSION=2.7.5

ENV DEBIAN_FRONTEND=noninteractive

ENV ANDROID_HOME=/opt/android-sdk-linux
ENV ANDROID_SDK_HOME=${ANDROID_HOME}
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV ANDROID_SDK=${ANDROID_HOME}
ENV ANDROID_NDK=/opt/android-ndk-linux
ENV ANDROID_NDK_ROOT=${ANDROID_NDK}
ENV GRADLE_PROFILER_HOME=/opt/gradle-profiler
ENV ALLURE_HOME=/opt/allure

ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin"
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/tools/bin"
ENV PATH="${PATH}:${ANDROID_HOME}/tools/bin"
ENV PATH="${PATH}:${ANDROID_HOME}/build-tools/30.0.3"
ENV PATH="${PATH}:${ANDROID_HOME}/build-tools/33.0.1"
ENV PATH="${PATH}:${ANDROID_HOME}/build-tools/34.0.0"
ENV PATH="${PATH}:${ANDROID_HOME}/build-tools/35.0.0"
ENV PATH="${PATH}:${ANDROID_HOME}/build-tools/35.0.1"
ENV PATH="${PATH}:${ANDROID_HOME}/build-tools/36.0.0"
ENV PATH="${PATH}:${ANDROID_HOME}/platform-tools"
ENV PATH="${PATH}:${ANDROID_HOME}/emulator"
ENV PATH="${PATH}:${ANDROID_HOME}/bin"
ENV PATH="${PATH}:${GRADLE_PROFILER_HOME}/bin"
ENV PATH="${PATH}:/opt/marathon/bin"
ENV PATH="${PATH}:${ALLURE_HOME}/bin"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    dpkg --add-architecture i386; \
    case "${APT_PROFILE}" in \
      ubuntu23_old_releases) \
        if [ -f /etc/apt/sources.list ]; then \
          sed -i -re 's/([a-z]{2}\\.)?archive.ubuntu.com|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list; \
        else \
          printf '%s\n' \
            'deb http://old-releases.ubuntu.com/ubuntu/ lunar main restricted universe multiverse' \
            'deb http://old-releases.ubuntu.com/ubuntu/ lunar-updates main restricted universe multiverse' \
            'deb http://old-releases.ubuntu.com/ubuntu/ lunar-security main restricted universe multiverse' \
            > /etc/apt/sources.list; \
        fi; \
        echo "deb http://security.ubuntu.com/ubuntu focal-security main universe" >> /etc/apt/sources.list; \
        ;; \
      ubuntu25_i386_focal) \
        touch /etc/apt/sources.list.d/i386.list; \
        if [ -f /etc/apt/sources.list ]; then \
          sed -i 's/^deb http/deb [arch=armhf] http/' /etc/apt/sources.list; \
        fi; \
        echo "deb [arch=i386] http://security.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse" >> /etc/apt/sources.list.d/i386.list; \
        echo "deb [arch=i386] http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse" >> /etc/apt/sources.list.d/i386.list; \
        echo "deb [arch=i386] http://archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse" >> /etc/apt/sources.list.d/i386.list; \
        echo "deb [arch=i386] http://archive.ubuntu.com/ubuntu/ focal-backports main restricted universe multiverse" >> /etc/apt/sources.list.d/i386.list; \
        echo "deb http://security.ubuntu.com/ubuntu focal-security main universe" >> /etc/apt/sources.list; \
        ;; \
      ubuntu24_toolchain) \
        if [ -f /etc/apt/sources.list ]; then \
          sed -i -re 's/([a-z]{2}\\.)?archive.ubuntu.com|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list; \
        fi; \
        echo "deb http://security.ubuntu.com/ubuntu focal-security main universe" >> /etc/apt/sources.list; \
        ;; \
      *) \
        echo "Unsupported APT_PROFILE: ${APT_PROFILE}"; \
        exit 1; \
        ;; \
    esac; \
    apt-get update -yqq; \
    if [[ "${APT_PACKAGES_CSV}" == *"amazon-corretto"* ]]; then \
      apt-get install -y --no-install-recommends ca-certificates wget gpg; \
      update-ca-certificates; \
      wget -O - https://apt.corretto.aws/corretto.key | gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg; \
      echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" > /etc/apt/sources.list.d/corretto.list; \
      apt-get update -yqq; \
    fi; \
    if [[ "${APT_PROFILE}" == "ubuntu24_toolchain" ]]; then \
      apt-get install -y --no-install-recommends software-properties-common; \
      add-apt-repository ppa:ubuntu-toolchain-r/test -y; \
      apt-get update -yqq; \
    fi; \
    if [[ -z "${APT_PACKAGES_CSV}" ]]; then \
      echo "APT_PACKAGES_CSV is required"; \
      exit 1; \
    fi; \
    IFS=',' read -r -a apt_packages <<< "${APT_PACKAGES_CSV}"; \
    apt-get install -y --no-install-recommends "${apt_packages[@]}"; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    if [[ -n "${JAVA_DEFAULT}" ]]; then \
      update-java-alternatives --set "${JAVA_DEFAULT}"; \
    fi

RUN set -eux; \
    if [[ "${ENABLE_GCC14}" == "true" ]]; then \
      update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 --slave /usr/bin/g++ g++ /usr/bin/g++-14; \
    fi

RUN groupadd android && useradd -d /opt/android-sdk-linux -g android android

COPY tools /opt/tools
COPY licenses /opt/licenses

RUN set -eux; \
    if [[ "${ENABLE_PROFILER}" == "true" ]]; then \
      mkdir -p "${GRADLE_PROFILER_HOME}"; \
      cd "${GRADLE_PROFILER_HOME}"; \
      wget https://repo1.maven.org/maven2/org/gradle/profiler/gradle-profiler/0.20.0/gradle-profiler-0.20.0.zip; \
      unzip gradle-profiler-0.20.0.zip; \
      mv -v gradle-profiler-0.20.0/* .; \
      rm -rf gradle-profiler-0.20.0 gradle-profiler-0.20.0.zip; \
    fi

RUN set -eux; \
    if [[ "${ENABLE_PYTHON2}" == "true" ]]; then \
      cd /tmp; \
      wget "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"; \
      tar --extract -f "Python-${PYTHON_VERSION}.tgz"; \
      cd "Python-${PYTHON_VERSION}"; \
      ./configure --enable-optimizations --prefix=/usr/local; \
      make; \
      make install; \
      cd /tmp; \
      rm -rf "Python-${PYTHON_VERSION}" "Python-${PYTHON_VERSION}.tgz"; \
      python --version; \
    fi

WORKDIR /opt/android-sdk-linux

RUN /opt/tools/entrypoint.sh built-in

RUN set -eux; \
    if [[ -z "${SDK_PACKAGES_CSV}" ]]; then \
      echo "SDK_PACKAGES_CSV is required"; \
      exit 1; \
    fi; \
    IFS=',' read -r -a sdk_packages <<< "${SDK_PACKAGES_CSV}"; \
    for package in "${sdk_packages[@]}"; do \
      /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "${package}"; \
    done

RUN set -eux; \
    if [[ "${ENABLE_MARATHON}" == "true" ]]; then \
      mkdir -p /opt/marathon; \
      cd /opt/marathon; \
      wget -q "https://github.com/MarathonLabs/marathon/releases/download/${MARATHON_VERSION}/marathon-${MARATHON_VERSION}.zip" -O marathon.zip; \
      unzip marathon.zip; \
      rm -f marathon.zip; \
      ln -sf "/opt/marathon/marathon-${MARATHON_VERSION}/bin/marathon" /usr/local/bin/marathon; \
      marathon version; \
    fi

RUN set -eux; \
    if [[ "${ENABLE_ALLURE}" == "true" ]]; then \
      mkdir -p "${ALLURE_HOME}"; \
      cd "${ALLURE_HOME}"; \
      wget -q "https://github.com/allure-framework/allure2/releases/download/${ALLURE_VERSION}/allure-${ALLURE_VERSION}.zip" -O allure.zip; \
      unzip allure.zip; \
      mv "allure-${ALLURE_VERSION}"/* .; \
      rm -rf "allure-${ALLURE_VERSION}" allure.zip; \
      allure --version; \
    fi

RUN set -eux; \
    if [[ "${ENABLE_EMULATOR}" == "true" ]]; then \
      command -v emulator >/dev/null; \
    fi

CMD /opt/tools/entrypoint.sh built-in
