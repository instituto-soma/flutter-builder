FROM cirrusci/flutter:2.0.2

RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y --no-install-recommends apt-utils

RUN sudo apt-get install -y ruby-full

RUN gem install bundler -N
# Install fastlane which is used on Linux to build and deploy Android
# builds to the Play Store.
RUN gem install fastlane -N

RUN yes "y" | flutter doctor --android-licenses
RUN flutter doctor -v
RUN echo "Flutter installed with success"

# Install basics
RUN apt-get install -y --no-install-recommends \
  git \
  wget \
  curl \
  zip \
  unzip \
  ca-certificates \
  gnupg \
  gettext-base
