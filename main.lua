import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/animation"
import "CoreLibs/timer"
import "CoreLibs/easing"

import "pdParticles"

import "songs"
import "game"
import "endScreen"
import "title"
import "menu"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local tmr <const> = pd.timer
local ease <const> = pd.easingFunctions
local menu <const> = pd.getSystemMenu()

pd.display.setRefreshRate(0)

-- pd.datastore.delete("settings")

local sortOptions <const> = {
	"artist",
	"name",
	"bpm"
}
sortBy = sortOptions[1]

-- Define variables
-- Menu Item Variables
local function addSongSelectMenuItem()
	return menu:addMenuItem("To Menu", function()
		toMenu = true
		if restart then
			restart = false
		end
	end)
end
local function addRestartMenuItem()
	return menu:addMenuItem("Restart", function()
		restart = true
		if toMenu then
			toMenu = false
		end
	end)
end
local function addToggleSfxMenuItem()
	return menu:addCheckmarkMenuItem("Hit SFX", playHitSfx, function(hitSfx)
		playHitSfx = hitSfx
		settings.sfx = hitSfx
		pd.datastore.write(settings, "settings")
	end)
end
local function addResetHiScoresMenuItem()
	return menu:addMenuItem("Reset HiScore", function()
		resetHiScores = true
		warningYTimer = tmr.new(animationTime, warningCurrentY, 5, ease.outCubic)
	end)
end
local function addSortByMenuItem()
	return menu:addOptionsMenuItem("Sort By", sortOptions, sortBy, function(option)
		sortBy = option
		sortSongs = true
	end)
end

addSongSelectMenuItem() --pause
addRestartMenuItem() --pause
addToggleSfxMenuItem() --settings
addResetHiScoresMenuItem() --settings
addSortByMenuItem() --pause

local gameState = "title"

local function draw()
	gfx.clear()

	if gameState == "song" then
		drawSong()
		--alert the user to use crank if docked
		if pd.isCrankDocked() then
			pd.ui.crankIndicator:draw()
		end
	elseif gameState == "songEndScreen" then
		drawEndScreen()
	elseif gameState == "songSelect" then
		drawSongSelect()
	elseif gameState == "menu" then
		drawMainMenu()
	elseif gameState == "credits" then
		gameState = "title"
	else
		drawTitleScreen()
	end

	pd.drawFPS(0, 0)

end


function pd.update()
	-- update inputs
	updateInputs()
	-- update timers
	tmr.updateTimers()
	
	-- reset system menu items
	menu:removeAllMenuItems()

	-- update the current game state
	if gameState == "song" then
		gameState = updateSong()
		addSongSelectMenuItem()
		addRestartMenuItem()
		addToggleSfxMenuItem()
	elseif gameState == "songEndScreen" then
		gameState = updateEndScreen()
		addSongSelectMenuItem()
	elseif gameState == "songSelect" then
		gameState = updateSongSelect()
		addResetHiScoresMenuItem()
		addSortByMenuItem()
	elseif gameState == "menu" then
		gameState = updateMainMenu()
	elseif gameState == "credits" then

	else
		gameState = updateTitleScreen()
	end

	draw()

end