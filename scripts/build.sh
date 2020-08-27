#!/bin/sh

xcodebuild archive -project CloudMinder.xcodeproj -scheme CloudMinder -archivePath $PWD/build/CloudMinder
xcodebuild -exportArchive -exportOptionsPlist export.plist -archivePath $PWD/build/CloudMinder.xcarchive -exportPath $PWD/build

mkdir -p build/dist/CloudMinder
cp -Rp build/CloudMinder.app build/dist/CloudMinder/
cp scripts/install.sh build/dist/CloudMinder/

cd build/dist && zip -r CloudMinder.zip CloudMinder && cd ../..
