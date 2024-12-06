package states;

import flixel.FlxG;
import flixel.FlxState;
import haxe.display.Display.Package;

class RhythmState extends FlxState
{
	var lastBeat:Int = 0;
	var curBeat:Int = 0;
	var BPM:Int = 100;

	override public function create()
	{
		super.create();
	}

	var time:Float = 0;

	override public function update(elapsed:Float)
	{
		time += elapsed;
		lastBeat = Math.floor(FlxG.sound.music.time / (60000 / BPM));
		if (lastBeat != curBeat)
		{
			beatHit();
			curBeat = lastBeat;
		}
		super.update(elapsed);
	}

	public function beatHit() {}
}
