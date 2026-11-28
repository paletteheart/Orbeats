import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/animation"
import "CoreLibs/timer"
import "CoreLibs/easing"

playdate.display.setRefreshRate(50) -- up here so image caches render right

import "common"
import "particles"
import "songs"
import "game"
import "endScreen"
import "title"
import "menu"
import "tutorials"
import "stats"
import "settings"
import "reset"
import "levelEditor"
import "discord"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local tmr <const> = pd.timer
local ease <const> = pd.easingFunctions
local menu <const> = pd.getSystemMenu()

local screenWidth <const> = 400
local screenHeight <const> = 240

-- Define variables

local gameState = "title"
if not settings.skipIntro then gameState = "splash" end
local oldGameState = gameState
-- local drawFunction

local function draw()

	if gameState == "song" then
		gfx.clear()
		drawSong()
		--alert the user to use crank if docked
		if pd.isCrankDocked() and not (tutorial or settings.noCrankMode) then
			pd.ui.crankIndicator:draw()
		end
	elseif gameState == "songEndScreen" then
		gfx.clear(gfx.kColorBlack)
		drawEndScreen()
	elseif gameState == "songSelect" then
		gfx.clear(gfx.kColorBlack)
		drawSongSelect()
	elseif gameState == "tutorialSelect" then
		gfx.clear(gfx.kColorBlack)
		drawTutorialSelect()
	elseif gameState == "menu" then
		gfx.clear(gfx.kColorBlack)
		drawMainMenu()
	elseif gameState == "settings" then
		gfx.clear(gfx.kColorBlack)
		drawSettings()
	elseif gameState == "stats" then
		gfx.clear(gfx.kColorBlack)
		drawStatsPage()
		--alert the user to use crank if docked
		if pd.isCrankDocked() then
			pd.ui.crankIndicator:draw()
		end
	elseif gameState == "reset" then
		gfx.clear()
		drawResetMenu()
	elseif gameState == "levelEditor" then
		drawLevelEditor()
	elseif gameState == "discord" then
		gfx.clear(gfx.kColorBlack)
		drawDiscordInvite()
	elseif gameState == "splash" then
		gfx.clear(gfx.kColorBlack)
		drawSplashes()
	else
		gfx.clear(gfx.kColorBlack)
		drawTitleScreen()
	end

	if settings.drawFps then
		if gameState == "song" and not tutorial then
			pd.drawFPS(screenWidth-15, 0)
		else
			pd.drawFPS(screenWidth-15, screenHeight-12)
		end
	end

end


pd.resetElapsedTime()

function pd.update()
	-- update inputs
	updateInputs()
	-- update timers
	tmr.updateTimers()
	-- update play time
	stats.playTime += pd.getElapsedTime()
	pd.resetElapsedTime()

	-- save stats if changing game state
	if gameState ~= oldGameState then
		pd.datastore.write(stats, "stats")
		oldGameState = gameState
	end

	-- update the current game state
	if gameState == "song" then
		gameState = updateSong()
		-- drawFunction = drawSong
	elseif gameState == "songEndScreen" then
		gameState = updateEndScreen()
		-- drawFunction = drawSong
	elseif gameState == "songSelect" then
		gameState = updateSongSelect()
	elseif gameState == "tutorialSelect" then
		gameState = updateTutorialSelect()
	elseif gameState == "menu" then
		gameState = updateMainMenu()
	elseif gameState == "settings" then
		gameState = updateSettings()
	elseif gameState == "stats" then
		gameState = updateStatsPage()
	elseif gameState == "reset" then
		gameState = updateResetMenu()
	elseif gameState == "levelEditor" then
		gameState = updateLevelEditor()
	elseif gameState == "discord" then
		gameState = updateDiscordInvite()
	elseif gameState == "credits" then
		gameState = "title"
	elseif gameState == "splash" then
		gameState = updateSplashes()
	else
		gameState = updateTitleScreen()
	end

	draw()

end

function pd.gameWillTerminate()
	pd.datastore.write(stats, "stats")
end
function pd.deviceWillSleep()
	pd.datastore.write(stats, "stats")
end
function pd.deviceWillLock()
	pd.datastore.write(stats, "stats")
end
function pd.deviceDidUnlock()
	-- make sure you don't count time locked in the total playtime
	pd.resetElapsedTime()
end

function pd.gameWillPause()
	-- used to update the values in the menu
	if gameState == "songSelect" then setSongSelectMenuItems() end
end
function pd.gameWillResume()
	-- for saving when you change the sorting or mods
	if gameState == "songSelect" then pd.datastore.write(settings, "settings") end
end

-- instantly restart the level in the simulator if pressed
function pd.keyPressed(key)
	if key == "r" then
		restart = true
		if toMenu then
			toMenu = false
		end
	end
end