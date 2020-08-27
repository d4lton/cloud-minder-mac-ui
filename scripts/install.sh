#!/bin/sh

killall CloudMinder
rm -rf /Applications/CloudMinder.app
cp -Rp CloudMinder.app /Applications/
open /Applications/CloudMinder.app
