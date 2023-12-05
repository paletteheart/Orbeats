
import "game"

-- Define constants
local pd <const> = playdate
local gfx <const> = pd.graphics

local songList = json.decodeFile(pd.file.open("songlist.json"))

function drawSongSelect()
    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned("Press up to start test song: "..songList[1].name, 200, 2, kTextAlignment.center)
end

function updateSongSelect()
    -- update inputs
    crankPos = pd.getCrankPosition()

    if upPressed then

        -- test code to automatically start the first song
        local bpm = songList[1].bpm
        local musicFile = "songs/"..songList[1].name.."/"..songList[1].name
        local songTable = json.decodeFile(pd.file.open("songs/"..songList[1].name.."/"..songList[1].difficulties[1]..".json"))
        local beatOffset = songList[1].beatOffset
        setUpSong(bpm, beatOffset, musicFile, songTable)
        return "song"
    end

    return "songSelect"
end