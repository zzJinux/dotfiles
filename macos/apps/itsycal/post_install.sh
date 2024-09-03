#!/usr/bin/env bash
app=com.mowglii.ItsycalApp.plist
defaults write $app ClockFormat -string "E yyMMdd HH:mm:ss"
defaults write $app HideIcon -bool true
defaults write $app PinItsycal -bool false
defaults write $app ShowEventDays -int 7

# Minimize the menubar clock
defaults write com.apple.menuextra.clock IsAnalog -bool true
