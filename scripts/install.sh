#!/bin/sh

launchctl unload ~/Library/LaunchAgents/com.basken.CloudMinder.plist 2> /dev/null
rm -rf /Applications/CloudMinder.app
cp -Rp CloudMinder.app /Applications/
cp com.basken.CloudMinder.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.basken.CloudMinder.plist
open /Applications/CloudMinder.app

