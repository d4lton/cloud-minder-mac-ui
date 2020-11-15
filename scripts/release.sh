#!/bin/sh

xcrun agvtool next-version -all

./scripts/build.sh
