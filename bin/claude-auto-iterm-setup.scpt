-- claude-auto iTerm2 Setup
-- Opens 5 tabs with claude-auto profiles: Launch, DevOps, JSA, CoreDev, AlomaStep
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

		-- Tab 4: CoreDev
		create tab with profile "CoreDev"

		-- Tab 5: AlomaStep
		create tab with profile "AlomaStep"

		-- Switch back to first tab (Launch)
		select first tab
	end tell
end tell
