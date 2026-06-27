#!/usr/bin/env sh
APP_BASE_NAME=$(basename "$0")
DIRNAME=$(dirname "$0")
X_BUILD_GRADLE="$DIRNAME/build.gradle"
if [ -f "$X_BUILD_GRADLE" ]; then
    exec gradle "$@"
else
    echo "Chyba: build.gradle nenalezen!"
    exit 1
fi
