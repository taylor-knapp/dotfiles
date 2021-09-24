#
# Setup Moonlander quick app open shortcuts.
# This trick involves some automator services and then tying them to shortcuts that map to quick actions on the keyboard.
#

# Copy automator services to the typical services directory.
cp -R $(dirname $0)/services/ ~/Library/Services/

# Add shortcuts for services to the pbs.plist.
/usr/libexec/PlistBuddy -c 'delete NSServicesStatus:"(null) - Launch Atom - runWorkflowAsService"' ~/Library/Preferences/pbs.plist
defaults write pbs NSServicesStatus -dict-add '"(null) - Launch Atom - runWorkflowAsService"' '{ "key_equivalent" = "@~^$a"; }'

/usr/libexec/PlistBuddy -c 'delete NSServicesStatus:"(null) - Launch Brave - runWorkflowAsService"' ~/Library/Preferences/pbs.plist
defaults write pbs NSServicesStatus -dict-add '"(null) - Launch Brave - runWorkflowAsService"' '{ "key_equivalent" = "@~^$b"; }'

/usr/libexec/PlistBuddy -c 'delete NSServicesStatus:"(null) - Launch DataGrip - runWorkflowAsService"' ~/Library/Preferences/pbs.plist
defaults write pbs NSServicesStatus -dict-add '"(null) - Launch DataGrip - runWorkflowAsService"' '{ "key_equivalent" = "@~^$d"; }'

/usr/libexec/PlistBuddy -c 'delete NSServicesStatus:"(null) - Launch Slack - runWorkflowAsService"' ~/Library/Preferences/pbs.plist
defaults write pbs NSServicesStatus -dict-add '"(null) - Launch Slack - runWorkflowAsService"' '{ "key_equivalent" = "@~^$s"; }'

/usr/libexec/PlistBuddy -c 'delete NSServicesStatus:"(null) - Launch Spotify - runWorkflowAsService"' ~/Library/Preferences/pbs.plist
defaults write pbs NSServicesStatus -dict-add '"(null) - Launch Spotify - runWorkflowAsService"' '{ "key_equivalent" = "@~^$p"; }'

/usr/libexec/PlistBuddy -c 'delete NSServicesStatus:"(null) - Launch WebStorm - runWorkflowAsService"' ~/Library/Preferences/pbs.plist
defaults write pbs NSServicesStatus -dict-add '"(null) - Launch WebStorm - runWorkflowAsService"' '{ "key_equivalent" = "@~^$m"; }'

/usr/libexec/PlistBuddy -c 'delete NSServicesStatus:"(null) - Launch Postman - runWorkflowAsService"' ~/Library/Preferences/pbs.plist
defaults write pbs NSServicesStatus -dict-add '"(null) - Launch Postman - runWorkflowAsService"' '{ "key_equivalent" = "@~^$o"; }'