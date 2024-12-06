package;

import Controls.Input;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;

typedef Setting =
{
	var value:Dynamic;
	@:optional var maxValue:Float;
	@:optional var minValue:Float;
}

class Settings
{
	public static var antialiasing:Bool = true;
	public static var framerate:Setting = {value: 120, maxValue: 240, minValue: 60}
	public static var hideHealthbars:Bool = false;
	public static var hideHealthText:Bool = false;
	public static var hideHUD:Bool = false;
	public static var damageTextNum:Setting = {value: 4, minValue: -1}

	public static function loadSettings()
	{
		if (FlxG.save.data.controls != null)
		{
			// Controls.INPUTS = FlxG.save.data.controls;
		}
		if (FlxG.save.data.antialiasing != null)
			antialiasing = FlxG.save.data.antialiasing;
		if (FlxG.save.data.framerate != null)
		{
			framerate.value = FlxG.drawFramerate = FlxG.updateFramerate = Std.int(FlxG.save.data.framerate.value);
		}
		if (FlxG.save.data.hideHealthbars != null)
			Settings.hideHealthbars = FlxG.save.data.hideHealthbars;
		if (FlxG.save.data.hideHealthText != null)
			Settings.hideHealthText = FlxG.save.data.hideHealthText;
		if (FlxG.save.data.hideHUD != null)
			Settings.hideHUD = FlxG.save.data.hideHUD;
		if (FlxG.save.data.damageTextNum != null)
			Settings.damageTextNum = FlxG.save.data.damageTextNum;
	}

	public static function saveSettings()
	{
		FlxG.save.data.controls = Controls.INPUTS;
		FlxG.save.data.framerate = Settings.framerate;
		FlxG.save.data.antialiasing = antialiasing;
		FlxG.save.data.hideHealthbars = Settings.hideHealthbars;
		FlxG.save.data.hideHealthText = Settings.hideHealthText;
		FlxG.save.data.hideHUD = Settings.hideHUD;
		FlxG.save.data.damageTextNum = Settings.damageTextNum;
		FlxG.save.flush();
	}
}
