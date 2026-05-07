#!/bin/bash
cd "$(dirname "$0")/android"
./gradlew assembleDebug --stacktrace --info 2>&1 | tee build_debug.log