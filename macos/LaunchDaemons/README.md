## Installation
```bash
plist_file=your.plist
sudo bash -c "cp $plist_file /Library/LaunchDaemons/ \
&& chown root:wheel /Library/LaunchDaemons/$plist_file \
&& chmod 644 /Library/LaunchDaemons/$plist_file \
&& launchctl load /Library/LaunchDaemons/$plist_file"
```