# Map Documentation
[Orbeats](https://github.com/paletteheart/Orbeats) is a simple rhythm game for the PlayDate heavily utilizing the crank with an easily expandable song list. Dedicated players can create and add custom maps to their game. This documents the details of creating a song map and adding it into the game.
## Adding custom songs/maps to your game
If you already have a song and it's difficulty maps created and ready to play in game, just follow these steps to add it into your game:
 1. Connect your PlayDate to a computer. If you're playing using the SDK's simulator, skip to step 3.
 2. Go to your PlayDate's settings. Scroll down to and select "System", and then scroll down and select "Reboot to Data Disk".
 3. On your computer, navigate to the PlayDate's (or Simulator's) "Data" folder, then to "com.paletteheart.orbeats", and then to "songs". If there is no 'songs' folder at the specified directory, you can just create one.
 4. Copy the custom song's folder into "songs".
 5. Eject your PlayDate.

And the level should then be within your game!

## Creating custom songs and maps
Create a new song, you'll need to create a folder for it's files (what will be referred to as the song's folder). I highly recommend that the song's folder's name be formatted like "song_title.artist.your_handle" to keep songs from sharing the same folder name. Inside that, you'll need:
 1. **songData.json** - A .json file containing data about the song that is the same between all maps. Info on creating this below.
 2. **albumArt.pdi**\* - A PlayDate image file, generated from a 64x64 .png using only black, white, and fully transparent pixels. Currently the only way to make these is to use the SDK to compile a project containing the .png, and taking the resulting .pdi file from the compiled .pdx folder.
 3. **[song name].pda** - The PlayDate audio file of the song, generated from a .wav file. You can convert a .wav file to .pda [here](https://ejb.github.io/wav-pda-converter/), or using the SDK. It's highly recommended that the wav file be 22k Hz and signed 16 bit PCM and ran through [ADPCM-XQ](https://github.com/dbry/adpcm-xq/releases) to keep the file size low. It's recommended the song file has a short amount of silence after if you're going to map the whole song. **The name of the file must match the name of the song as defined in songData.json.**
 4. **[difficulty map].json** - One of the maps for the song. A single song can have any amount of difficulty maps, as long as they're all uniquely named. **For a map to be playable, it must have it's name in the list of difficulties within songData.json.** Info on creating these below.
 5. **[difficulty map].pdi**\* - One of the map's 48x48 icons. **It's name must match the name of a difficulty map.**

\* \- Optional. Can be left out of a song folder without causing errors.
### Creating the songData.json file
songData.json files follow this specific format:

```JSON
{
	"name":"",
	"artist":"",
	"difficulties":[
		""
	],
	"bpm":0,
	"bpmChanges":[
		{
			"beat":0,
			"bpm":0
		}
	],
	"beatOffset":0,
	"preview":0
}
```

Any attribute followed by a 0 takes a number as input, and any attribute followed by "" takes a string.

 - **name** - The name of the song. **Should be the same as the name of the song's folder, as well as .pda file in the song's folder.**
 - **artist** - The song's artist.
 - **difficulties** - A list of the difficulty maps within the song's folder. **Each entry in the list should be the name of one of the difficulty maps within the song's folder without .json at the end. It is highly recommended that you order these from easiest to hardest.**
 - **bpm** - The bpm of the song.
 - **bpmChanges**\* - A list of objects defining when to change the bpm of the song, and what to change it to. **Does not change the speed of the audio, just the beats per minute.** *The beat count will not change after a bpm change, just the speed of the beats; i.e. if you change bpm at beat 50, it will remain beat 50, but the subsequent beats will be at a different speed.*
	 - Each bpm change object is defined by a set of attributes:
		 - **beat** - The beat at which the bpm will change.
		 - **bpm** - The bpm to change to.
 - **beatOffset** - How much to offset beats when playing the song, in beats. Used for keeping the beats of the map aligned with the beat of the music. As a use example, if the song is half a beat early from the mappings, you can set this to 0.5 to fix this.
 - **preview** - When in the music file to start the preview when on the song select menu, in seconds. **Must have at least ten seconds of audio after.**

\* \- Optional. Can be left out of a song folder without causing errors.
### Creating a custom difficulty map
A custom map for a song is stored as a .json file, following this overall structure:

```JSON
{
	"notes":[
		{
			"type":"",
			"spawnBeat":0,
			"hitBeat":0,
			"speed":0,
			"width":0,
			"position":0,
			"spin":0,
			"duration":0
		}
	],
	"effects":{
		"toggleInvert":[
			0
		],
		"moveOrbitX":[
			{
				"beat":0,
				"x":0,
				"animation":"",
				"power":0
			}
		],
		"moveOrbitY":[
			{
				"beat":0,
				"y":0,
				"animation":"",
				"power":0
			}
		],
		"text":[
			{
				"startBeat":0,
				"endBeat":0,
				"text":"",
				"x":0,
				"y":0,
				"font":""
			}
		]
	},
	"songEnd":0
}
```

Any attribute followed by a 0 takes a number as input, and any attribute followed by "" takes a string.
 - **notes** - List of note objects.
	 - Each note is defined by a set of attributes:
		 - **type**\* - The type of the note. Can be either "Note", "HoldNote", or "FlipNote". "Note" will make it a normal note, hit by pressing down/B while in the right place. "HoldNote" will make it a note that is hit if you're holding up/A/down/B and are in the right place. "FlipNote" will make it a note that you hit by pressing up/A and flipping to the other side while in the right place. *Defaults to “Note”.*
		 - **spawnBeat** - The beat of the song when this note will be spawned in. **Notes are expected to be in order by their spawnBeat, earlier notes coming first. Putting notes out of order will cause them to play incorrectly.**
		 - **hitBeat** - The beat of the song when this note will reach the orbit radius and can be hit by the cursor. Notes may share a hitBeat.
		 - **speed**\* - How quickly the note approaches the orbit radius. *Defaults to 1.*
		 - **width**\* - How wide the note is in degrees. *Defaults to 45.*
		 - **position** - A number from 0 to 360 determining where the middle of the note will be, in degrees, when it reaches the orbit radius.
		 - **spin**\* - The number of degrees the note will spin around before reaching the orbit. Negative for counter clockwise. *Defaults to 0.*
		 - **duration**\* - The length the note will need to be held to score full points on it. **This attribute only applies if the type is “Note” or “HoldNote”.** If set to 0, the note won’t need to be held at all. *Defaults to 0.*
 - **effects**\* - An object containing lists of all the visual effects.
	 - **toggleInvert**\* - A list of beats when the screen will invert. **Beats are expected to be ordered from earliest to latest.**
	 - **moveOrbitX**\* - A list of objects defining when, where, and how the orbit will move along the x axis.
		 - Each x movement object is defined by a set of attributes:
			 - **beat** - The beat when a note will reach this object's defined x value. **Movement objects are expected to be in beat order, with earlier movements before later ones.**
			 - **x** - The x value the center of the orbit will move to. Set to 200 (screen center) by default.
			 - **animation**\* - The animation the orbit will take to reach the x value. Can be any easing function from the PlayDate library, "ease-in", "ease-out", or "none". *Defaults to "none".*
			 - **power**\* - If the animation is set to be "ease-in" or "ease-out", this will define how quickly it'll ease in or out, or will passed as the fifth argument for any other easing function.
	 - **moveOrbitY**\* - A list of objects defining when, where, and how the orbit will move along the y axis.
		 - Each y movement object is defined by a set of attributes:
			 - **beat** - The beat when a note will reach this object's defined y value. **Movement objects are expected to be in beat order, with earlier movements before later ones.**
			 - **y** - The x value the center of the orbit will move to. Set to 120 (screen center) by default.
			 - **animation**\* - The animation the orbit will take to reach the x value. Can be any easing function from the PlayDate library, "ease-in", "ease-out", or "none". *Defaults to "none".*
			 - **power**\* - If the animation is set to be "ease-in" or "ease-out", this will define how quickly it'll ease in or out, or will passed as the fifth argument for any other easing function.
	 - **text**\* - A list of objects defining when, where, and what text will show on the screen. *Text will be drawn centered horizontally and vertically to the given x and y.*
		 - Each text object is defined by a set of attributes:
			 - **startBeat** - The beat at which this object's text will be shown.
			 - **endBeat** - The beat at which this object's text will be removed.
			 - **text** - A string of text that will be shown.
			 - **x** - The x value where the center of the text will be.
			 - **y** - The y value where the center of the text will be.
			 - **font**\* - The font that will be used. Can be set to "orbeatsSans", "odinRounded", or "orbeatsSmall". *Defaults to "orbeatsSmall".*
 - **songEnd** - The beat when the map will end.

\* \- Optional. Can be left out of a map file without causing errors.
