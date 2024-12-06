package;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

enum abstract Input(String)
{
	var LEFT;
	var RIGHT;
	var UP;
	var DOWN;
	var DIVE;
	var MELEE;
	var ATTACK1;
	var ATTACK2;
	var ATTACK3;
	var PAUSE;
	var ACCEPT;
	var BACK;
	var INTERACT;
	var ULT;
	var INVENTORY;
}

class Controls
{
	public static var INPUTS:Map<Input, Array<FlxKey>> = [
		Input.LEFT => [FlxKey.A, FlxKey.LEFT],
		Input.RIGHT => [FlxKey.D, FlxKey.RIGHT],
		Input.UP => [FlxKey.W, FlxKey.UP],
		Input.DOWN => [FlxKey.S, FlxKey.DOWN],
		Input.DIVE => [FlxKey.SHIFT, FlxKey.CONTROL],
		Input.MELEE => [FlxKey.ONE, FlxKey.Z],
		Input.ATTACK1 => [FlxKey.TWO, FlxKey.X],
		Input.ATTACK2 => [FlxKey.THREE, FlxKey.C],
		Input.ATTACK3 => [FlxKey.FOUR, FlxKey.V],
		Input.PAUSE => [FlxKey.ESCAPE, FlxKey.BACKSPACE],
		Input.ACCEPT => [FlxKey.ENTER, FlxKey.SPACE],
		Input.BACK => [FlxKey.BACKSPACE, FlxKey.BACKSLASH],
		Input.INTERACT => [FlxKey.E, FlxKey.X],
		Input.ULT => [FlxKey.FIVE, FlxKey.TAB],
		Input.INVENTORY => [FlxKey.I, FlxKey.E]
	];

	public function new() {}

	inline public function getPressed(input:Input):Bool
	{
		return FlxG.keys.anyPressed(INPUTS[input]);
	}

	inline public function getJustPressed(input:Input):Bool
	{
		return FlxG.keys.anyJustPressed(INPUTS[input]);
	}

	inline public function getReleased(input:Input):Bool
	{
		return FlxG.keys.anyJustReleased(INPUTS[input]);
	}
}
