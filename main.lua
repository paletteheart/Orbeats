import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/ui"

import "songs"
import "game"
import "endScreen"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local menu <const> = pd.getSystemMenu()

local sortOptions <const> = {
	"artist",
	"name"
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

local songSelectMenuItem = addSongSelectMenuItem()
local restartMenuItem = addRestartMenuItem()
local resetHiScoresMenuItem = addResetHiScoresMenuItem()
local sortByMenuItem = addSortByMenuItem()

local gameState
gameState = "songSelect"

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
	else

	end

	-- pd.drawFPS(2, 62)

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
	elseif gameState == "songEndScreen" then
		gameState = updateEndScreen()
		songSelectMenuItem = addSongSelectMenuItem()
	elseif gameState == "songSelect" then
		gameState = updateSongSelect()
		resetHiScoresMenuItem = addResetHiScoresMenuItem()
		sortByMenuItem = addSortByMenuItem()
	else

	end

	draw()

end