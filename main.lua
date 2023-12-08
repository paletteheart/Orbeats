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

-- Define variables
-- Menu Item Variables
local function addSongSelectMenuItem()
	return menu:addMenuItem("To Menu", function()
		toMenu = true
	end)
end
local function addResetHiScoresMenuItem()
	return menu:addMenuItem("Reset HiScore", function()
		resetHiScores = true
		warningTargetY = 5
	end)
end

local songSelectMenuItem = addSongSelectMenuItem()
local resetHiScoresMenuItem = addResetHiScoresMenuItem()

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
	elseif gameState == "songEndScreen" then
		gameState = updateEndScreen()
		songSelectMenuItem = addSongSelectMenuItem()
	elseif gameState == "songSelect" then
		gameState = updateSongSelect()
		resetHiScoresMenuItem = addResetHiScoresMenuItem()
	else

	end

	draw()

end