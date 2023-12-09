# Orbeats Map Documentation
[Orbeats](https://github.com/paletteheart/Orbeats) is a simple rhythm game for the PlayDate heavily utilizing the crank with an easily expandable song list. Dedicated players can create and add custom maps to their game. This documents the details of creating a song map and adding it into the game.
## Adding custom songs/maps
If all you want to do is add in a song with premade difficulty maps, follow these steps:

 1. **Add the song's folder to the song folder.** The folder the maps are in should be the name of the song, and the maps should be named after their difficulty level. Inside should be at least one difficulty map, the .wav file of the song, and a 64x64 1-bit png to act as the song's album art.
 2. **Add the song's data to songlist.json.** At the end of the file, you'll want to append a new object that will follow this template:
	
	     {
		     "name":"",
		     "artist":"",
		     "difficulties":[
			   	 ""
		     ],
		     "bpm":#,
		   	 "beatOffset":#
	     }

	Any attribute followed by a # takes a number as input, and any attribute followed by "" takes a string.
	
	 - **name** - The name of the song. **Should be the same as the name of the song's folder and the .wav file in the song's folder.**
	 - **artist** - The song's artist.
	 - **difficulties** - A list of the difficulty maps within the song's folder. **Each entry in the list should be the name of one of the difficulty maps within the song's folder without .json at the end.**
	 - **bpm** - The bpm of the song.
	 - **beatOffset** - How much to offset beats when playing the song. Used for keeping the beats of the map aligned with the beat of the music.

	
That should be all you need to do for the song and it's maps to show up in game.

## Creating custom maps
A custom map for a song is stored as a .json file, following this overall structure:
		
		{
			"notes":[
				{
					"type":"",
					"spawnBeat":#,
					"hitBeat":#,
					"speed":#,
					"width":#,
					"position":#,
					"spin":#
				}
			],
			"effects":{
				"toggleInvert":[
					#
				],
				"moveOrbitX":[
					{
						"beat":#,
						"x":#,
						"animation":"",
						"power":#
					}
				],
				"moveOrbitY":[
					{
						"beat":#,
						"y":#,
						"animation":"",
						"power":#
					}
				],
				"text":[
					{
						"startBeat":#,
						"endBeat":#,
						"text":"",
						"x":#,
						"y":#
					}
				]
			},
			"songEnd":#
		}
Any attribute followed by a # takes a number as input, and any attribute followed by "" takes a string.
 - **notes** - List of note objects.
	 - Each note is defined by a set of attributes:
		 - **type** - The type of the note. Can be either "note" or "flipnote"; the former will make it a note you hit by being in the right place when it reaches the orbit radius, and the latter you hit by being in the right place and flipping to the other side when it reaches the orbit radius.
		 - **spawnBeat** - The beat of the song when this note will be spawned in. **Notes are expected to be in order by their spawnBeat, earlier notes coming first. Two notes cannot share a spawnBeat.**
		 - **hitBeat** - The beat of the song when this note will reach the orbit radius and can be hit by the cursor. Notes may share a hitBeat.
		 - **speed** - How quickly the note approaches the orbit radius.
		 - **width** - How wide the note is.
		 - **position** - A number from 0 to 360 determining where the middle of the note will be, in degrees, when it reaches the orbit radius.
		 - **spin** - How quickly the note will spin around as it approaches the orbit radius. Set it to 0 for no spin.
 - **effects** - An object containing lists of all the visual effects.
	 - **toggleInvert*** - A list of beats when the screen will invert. **Beats are expected to be ordered from earliest to latest.**
	 - **moveOrbitX*** - A list of objects defining when, where, and how the orbit will move along the x axis.
		 - Each x movement object is defined by a set of attributes:
			 - **beat** - The beat when a note will reach this object's defined x value. **Movement objects are expected to be in beat order, with earlier movements before later ones.**
			 - **x** - The x value the orbit will move to.
			 - **animation** - The animation the orbit will take to reach the x value. Can be "linear", "ease-in", "ease-out", or "none".
			 - **power** - If the animation is set to be "ease-in" or "ease-out", this will define how quickly it'll ease in or out. Doesn't do anything for any other animation value.
	 - **moveOrbitY*** - A list of objects defining when, where, and how the orbit will move along the y axis.
		 - Each y movement object is defined by a set of attributes:
			 - **beat** - The beat when a note will reach this object's defined y value. **Movement objects are expected to be in beat order, with earlier movements before later ones.**
			 - **y** - The y value the orbit will move to.
			 - **animation** - The animation the orbit will take to reach the y value. Can be "linear", "ease-in", "ease-out", or "none".
			 - **power** - If the animation is set to be "ease-in" or "ease-out", this will define how quickly it'll ease in or out. Doesn't do anything for any other animation value.
	 - **text*** - A list of objects defining when, where, and what text will show on the screen.
		 - Each text object is defined by a set of attributes:
			 - **startBeat** - The beat at which this object's text will be shown.
			 - **endBeat** - The beat at which this object's text will be removed.
			 - **text** - A string of text that will be shown.
			 - **x** - The x value where the top left of the text will be.
			 - **y** - The y value where the top left of the text will be.
 - **songEnd** - The beat when the map will end.

\* \- Optional. Can be left out of a map file without causing errors.
