FROM ubuntu:18.04
MAINTAINER devops@institutosoma.org.br

ARG ANDROID_SDK_ROOT='/opt/android-sdk'
ARG ANDROID_HOME=${ANDROID_SDK_ROOT}
ARG ANDROID_SDK_PLATFORM=28
ARG ANDROID_SDK_TOOLS_VERSION=4333796
ARG ANDROID_BUILD_TOOLS_VERSION=28.0.3
ARG FLUTTER_HOME='/opt/flutter'
ARG FLUTTER_VERSION=1.2.1

WORKDIR /var/www

ENV PATH="${PATH}:${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/tools:${ANDROID_SDK_ROOT}/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/build-tools/${ANDROID_BUILD_TOOLS_VERSION}"

RUN \
#Install dependencies
# ---------------------------------------------------
echo "\n\nInstalling dependencies and cleaning cache" && \
apt-get update -qq && \
apt-get install -qq --no-install-recommends curl git lib32stdc++6 xz-utils unzip openjdk-8-jdk libglu1-mesa openssh-client -y > /dev/null && \
apt-get clean && rm -rf /var/lib/apt/lists/* && \
\
#Download and install Flutter
# ---------------------------------------------------
curl -Ls https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_v${FLUTTER_VERSION}-stable.tar.xz -o ./flutter.tar.xz && \
echo "\n\nDownloading and installing Flutter ${FLUTTER_VERSION}" && \
tar -xJf ./flutter.tar.xz && \
rm ./flutter.tar.xz && \
mv flutter /opt && \
flutter config --no-analytics && \
echo "Flutter installed with success" ; \
\
#Download and install Android SDK Manager
# ---------------------------------------------------
echo "\n\nDownloading and installing Android SDK ${ANDROID_SDK_TOOLS_VERSION}" && \
mkdir -p ${ANDROID_SDK_ROOT} && cd ${ANDROID_SDK_ROOT} && \
curl -Ls https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip -o android-sdk.zip && \
unzip -q android-sdk.zip && \
rm ./android-sdk.zip && \
echo "Android SDK installed with success"

#Accept Android SDK Manager licenses
# ---------------------------------------------------
RUN \
echo "\n\nAccepting Android SDK Manager licenses" && \
mkdir -p /root/.android && \
touch /root/.android/repositories.cfg && \
yes | sdkmanager --licenses > /dev/null && \
echo "All licenses accepted" ; \
\
#Install Android SDK Tools
# ---------------------------------------------------
echo "\n\nInstalling Android SDK build tools ${ANDROID_BUILD_TOOLS_VERSION} and platform tools ${ANDROID_SDK_PLATFORM}" && \
sdkmanager --verbose "platform-tools" "platforms;android-${ANDROID_SDK_PLATFORM}" "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" && \
echo "\n\nInstalling Android Repository, Google Repository and Google Play Services" && \
sdkmanager --verbose "extras;android;m2repository" "extras;google;m2repository"  "extras;google;google_play_services" && \
ls -l /opt/android-sdk/

CMD tail -f /dev/null
