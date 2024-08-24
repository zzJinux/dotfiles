tell application "System Events" to tell application process "Ivanti Secure Access Client"
	# Select Profile A
	click UI element 1 of UI element 5 of scroll area 1 of window "Ivanti Secure Access Client"
	
	# Suspend
	click menu item "Suspend" of menu 1 of menu item "Connections" of menu 1 of menu bar item "File" of menu bar 1
	
	# Select Profile B
	click UI element 1 of UI element 6 of scroll area 1 of window "Ivanti Secure Access Client"
	
	# Resume
	click menu item "Resume" of menu 1 of menu item "Connections" of menu 1 of menu bar item "File" of menu bar 1
end tell