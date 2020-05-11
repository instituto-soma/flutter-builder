FROM ruby:2.6.3-stretch

RUN apt-get update -y
RUN apt-get upgrade -y

# Install basics
RUN apt-get install -y --no-install-recommends \
  git \
  wget \
  curl \
  zip \
  unzip \
  ca-certificates \
  gnupg

# Add nodejs repository to apt sources and install it.
ENV NODEJS_INSTALL="/opt/nodejs_install"
RUN mkdir -p "${NODEJS_INSTALL}"
RUN wget -q https://deb.nodesource.com/setup_10.x -O "${NODEJS_INSTALL}/nodejs_install.sh"
RUN bash "${NODEJS_INSTALL}/nodejs_install.sh"

# Install the rest of the dependencies.
RUN apt-get install -y --no-install-recommends \
  locales \
  golang \
  nodejs \
  lib32stdc++6 \
  libstdc++6 \
  libglu1-mesa \
  build-essential \
  default-jdk-headless

# Install the Android SDK Dependency.
ENV ANDROID_SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip"
ENV ANDROID_TOOLS_ROOT="/opt/android_sdk"
RUN mkdir -p "${ANDROID_TOOLS_ROOT}"
RUN mkdir -p ~/.android
# Silence warning.
RUN touch ~/.android/repositories.cfg
ENV ANDROID_SDK_ARCHIVE="${ANDROID_TOOLS_ROOT}/archive"
RUN wget --progress=dot:giga "${ANDROID_SDK_URL}" -O "${ANDROID_SDK_ARCHIVE}"
RUN unzip -q -d "${ANDROID_TOOLS_ROOT}" "${ANDROID_SDK_ARCHIVE}"
# Suppressing output of sdkmanager to keep log size down
# (it prints install progress WAY too often).
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "tools" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "build-tools;28.0.3" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "platforms;android-28" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "platform-tools" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "extras;android;m2repository" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "extras;google;m2repository" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "patcher;v4" > /dev/null
RUN rm "${ANDROID_SDK_ARCHIVE}"
ENV PATH="${ANDROID_TOOLS_ROOT}/tools:${PATH}"
ENV PATH="${ANDROID_TOOLS_ROOT}/tools/bin:${PATH}"
# Silence warnings when accepting android licenses.
RUN mkdir -p ~/.android
RUN touch ~/.android/repositories.cfg

# Setup gradle
ENV GRADLE_ROOT="/opt/gradle"
RUN mkdir -p "${GRADLE_ROOT}"
ENV GRADLE_ARCHIVE="${GRADLE_ROOT}/gradle.zip"
ENV GRADLE_URL="https://services.gradle.org/distributions/gradle-6.0.1-all.zip"
RUN wget --progress=dot:giga "$GRADLE_URL" -O "${GRADLE_ARCHIVE}"
RUN unzip -q -d "${GRADLE_ROOT}" "${GRADLE_ARCHIVE}"
ENV PATH="$GRADLE_ROOT/bin:$PATH"

# Add npm to path.
ENV PATH="/usr/bin:${PATH}"
RUN dpkg-query -L nodejs
# Install Firebase
# This is why we need nodejs installed.
RUN /usr/bin/npm --verbose install -g firebase-tools

# Install dashing
# This is why we need golang installed.
RUN mkdir -p /opt/gopath/bin
ENV GOPATH=/opt/gopath
ENV PATH="${GOPATH}/bin:${PATH}"
#RUN go get -u github.com/technosophos/dashing

# Set locale to en_US
RUN locale-gen en_US "en_US.UTF-8" && dpkg-reconfigure locales
ENV LANG en_US.UTF-8

# Install coveralls and Firebase
# This is why we need ruby installed.
# Skip all the documentation (-N) since it's just on CI.
RUN gem install coveralls -N
RUN gem install bundler -N
# Install fastlane which is used on Linux to build and deploy Android
# builds to the Play Store.
RUN gem install fastlane -N

WORKDIR /var/www

ENV FLUTTER_VERSION=1.17.0
ENV FLUTTER_HOME='/opt/flutter'

ENV PATH="${PATH}:${FLUTTER_HOME}/bin"
RUN curl -Ls https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -o ./flutter.tar.xz 
RUN echo "\n\nDownloading and installing Flutter ${FLUTTER_VERSION}" 
RUN tar -xJf ./flutter.tar.xz -C /opt
RUN rm ./flutter.tar.xz 
RUN flutter config --no-analytics 
RUN flutter precache --all-platforms

ENV ANDROID_SDK_ROOT=${ANDROID_TOOLS_ROOT}
ENV ANDROID_HOME={ANDROID_SDK_ROOT}

ENV PATH="${PATH}:${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/tools:${ANDROID_SDK_ROOT}/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/build-tools/28.0.3:${ANDROID_HOME}"

RUN yes "y" | flutter doctor --android-licenses
RUN flutter doctor -v
RUN echo "Flutter installed with success"

RUN apt-get install -y --no-install-recommends gettext-base

RUN rm -rf /var/lib/apt/lists/* \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.UTF-8