package states;

import Settings.Setting;
import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor.*;

class PreferencesState extends FlxState
{
	var controls:Controls = new Controls();
	var preferences:Array<Array<String>> = [
		["FRAMERATE", "framerate"],
		["GLOBAL ANTIALIASING", "antialiasing"],
		["HIDE HEALTHBARS", "hideHealthbars"],
		["HIDE HEALTH TEXTS", "hideHealthText"],
		["HIDE HUD", "hideHUD"],
		["MAX DAMAGE TEXTS", "damageTextNum"]
	];
	var grpOptions:Array<FlxText> = [];
	var grpVars:Array<FlxText> = [];
	var curSelected:Int = 0;
	var rightArrow:FlxText;
	var leftArrow:FlxText;

	override public function create()
	{
		for (i in 0...preferences.length)
		{
			final optionText:FlxText = new FlxText(100, i * 100 + 100, 0, preferences[i][0], 72, true);
			add(optionText);
			grpOptions.push(optionText);
			var modsImChicken = Reflect.getProperty(Settings, preferences[i][1]);
			if (Reflect.hasField(modsImChicken, "value"))
				modsImChicken = modsImChicken.value;
			var varText:FlxText = new FlxText(optionText.x + optionText.width + 100, optionText.y, Std.string(modsImChicken), 72);
			add(varText);
			varText.ID = optionText.ID = i;
			varText.font = optionText.font = AssetPaths.Crang__ttf;
			grpVars.push(varText);
		}
		rightArrow = new FlxText(0, 0, 0, ">", 128);
		leftArrow = new FlxText(0, 0, 0, "<", 128);
		leftArrow.font = rightArrow.font = AssetPaths.Crang__ttf;
		add(rightArrow);
		add(leftArrow);
		changeSelection(0);
		super.create();
	}

	function placeArrows()
	{
		leftArrow.setPosition(grpVars[curSelected].x - leftArrow.width, grpVars[curSelected].y + (grpVars[curSelected].height - leftArrow.height) / 2);
		rightArrow.setPosition(grpVars[curSelected].x + grpVars[curSelected].width, leftArrow.y);
	}

	var selectionTweens:Array<FlxTween> = [];

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected >= grpOptions.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = grpOptions.length - 1;
		var j:Int = 0;
		for (i in 0...grpOptions.length)
		{
			final swagNum = -100 * curSelected + i * 100 + (FlxG.height - grpVars[i].height) / 2;

			selectionTweens[j]?.cancel();
			selectionTweens[j]?.destroy();
			selectionTweens[j] = FlxTween.tween(grpVars[i], {y: swagNum}, 0.5, {ease: FlxEase.quadOut});
			j++;
			selectionTweens[j]?.cancel();
			selectionTweens[j]?.destroy();
			selectionTweens[j] = FlxTween.tween(grpOptions[i], {y: swagNum}, 0.5, {ease: FlxEase.quadOut});
			j++;

			grpOptions[i].color = grpVars[i].color = (i == curSelected ? RED : WHITE);
		}
	}

	override public function update(elapsed:Float)
	{
		var the_setting:Dynamic = Reflect.getProperty(Settings, preferences[curSelected][1]);
		var leftP = controls.getPressed(LEFT);
		var rightP = controls.getPressed(RIGHT);
		var mouseRP = FlxG.mouse.overlaps(rightArrow) && FlxG.mouse.justPressed;
		var mouseLP = FlxG.mouse.overlaps(leftArrow) && FlxG.mouse.justPressed;

		if (leftP || rightP || mouseLP || mouseRP)
		{
			if (Reflect.hasField(the_setting, "value"))
			{
				the_setting.value += leftP || mouseLP ? -1 : 1;
				controls.getPressed(LEFT)
				|| mouseLP ? leftArrow.color = BLUE : rightArrow.color = BLUE;
				if (the_setting.maxValue != null && the_setting.value > the_setting.maxValue)
					the_setting.value = the_setting.minValue == null ? the_setting.maxValue : the_setting.minValue;
				if (the_setting.minValue != null && the_setting.value < the_setting.minValue)
					the_setting.value = the_setting.maxValue == null ? the_setting.minValue : the_setting.maxValue;
				Reflect.setProperty(Settings, preferences[curSelected][1], the_setting);
				grpVars[curSelected].text = Std.string(the_setting.value);
			}}
		else
		{
			leftArrow.color = rightArrow.color = RED;
		}
		if (controls.getJustPressed(LEFT) || controls.getJustPressed(RIGHT) || mouseLP || mouseRP)
		{
			if (Std.isOfType(the_setting, Bool))
			{
				the_setting = !the_setting;
				Reflect.setProperty(Settings, preferences[curSelected][1], the_setting);
				grpVars[curSelected].text = the_setting;
				controls.getJustPressed(LEFT)
				|| mouseLP ? leftArrow.color = BLUE : rightArrow.color = BLUE;
			}}
		else if (controls.getJustPressed(BACK))
		{
			Settings.saveSettings();
			Settings.loadSettings();
			FlxG.switchState(new OptionsState(OptionsState.targetState, OptionsState.args));
		}
		else if (controls.getJustPressed(UP) || FlxG.mouse.wheel > 0)
			changeSelection(-1);
		else if (controls.getJustPressed(DOWN) || FlxG.mouse.wheel < 0)
			changeSelection(1);
		placeArrows();

		super.update(elapsed);
	}
}
