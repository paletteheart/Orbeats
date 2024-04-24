import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/animation"

import "pdParticles"

import "songs"
import "game"
import "endScreen"
import "title"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local menu <const> = pd.getSystemMenu()

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
		warningTargetY = 5
	end)
end
local function addSortByMenuItem()
	return menu:addOptionsMenuItem("Sort By", sortOptions, sortBy, function(option)
		sortBy = option
		sortSongs = true
	end)
end
local function addTutorialMenuItem()
	return menu:addMenuItem("Tutorial", function()
		tutorialStarting = true
		songStarting = false
		tutorialPlayed = true
		settings.tutorial = tutorialPlayed
		pd.datastore.write(settings, "settings")
	end)
end

local songSelectMenuItem = addSongSelectMenuItem()
local restartMenuItem = addRestartMenuItem()
local toggleSfxMenuItem = addToggleSfxMenuItem()
local resetHiScoresMenuItem = addResetHiScoresMenuItem()
local sortByMenuItem = addSortByMenuItem()
local tutorialMenuItem = addTutorialMenuItem()

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
	elseif gameState == "credits" then
		gameState = "title"
	else
		drawTitle()
	end

	-- pd.drawFPS(0, 0)

end


function pd.update()
	-- update inputs
	updateInputs()
	
	-- reset system menu items
	menu:removeAllMenuItems()

	-- update the current game state
	if gameState == "song" then
		gameState = updateSong()
		songSelectMenuItem = addSongSelectMenuItem()
		restartMenuItem = addRestartMenuItem()
		toggleSfxMenuItem = addToggleSfxMenuItem()
	elseif gameState == "songEndScreen" then
		gameState = updateEndScreen()
		songSelectMenuItem = addSongSelectMenuItem()
	elseif gameState == "songSelect" then
		gameState = updateSongSelect()
		resetHiScoresMenuItem = addResetHiScoresMenuItem()
		tutorialMenuItem = addTutorialMenuItem()
		sortByMenuItem = addSortByMenuItem()
	elseif gameState == "credits" then

	else
		gameState = updateTitle()
	end

	draw()

end