-- claude-auto iTerm2 Setup
-- Opens 6 tabs with claude-auto profiles: Launch, DevOps, JSA, ALOMA Core, AlomaStep, Medical
-- Run once to create the window, then save as Default Window Arrangement

tell application "iTerm2"
	activate

	-- Create a new window with the Terminal profile (claude-auto launch)
	create window with profile "Terminal"

	tell current window
		-- Tab 2: DevOps
		create tab with profile "DevOps"

		-- Tab 3: JSA
		create tab with profile "JSA"

		-- Tab 4: ALOMA Core (claude-auto adev)
		create tab with profile "ALOMA Core"

		-- Tab 5: AlomaStep
		create tab with profile "AlomaStep"

		-- Tab 6: Medical (claude-auto medical)
		create tab with profile "Medical"

		-- Switch back to first tab (Launch)
		select first tab
	end tell
end tell
