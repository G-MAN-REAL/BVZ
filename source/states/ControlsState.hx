package states;

import Controls.Input;
import flixel.FlxG;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class ControlsState extends FlxState
{
	var keys:Array<FlxText> = [];
	var inputs:Array<FlxText> = [];
	var keysAlt:Array<FlxText> = [];
	var curSelected:Int = 0;
	var inputsRaw:Array<String> = [
		"LEFT", "RIGHT", "UP", "DOWN", "DIVE", "MELEE", "ATTACK1", "ATTACK2", "ATTACK3", "PAUSE", "ACCEPT", "BACK", "INTERACT", "ULT", "INVENTORY"
	]; // for ordering we use the simplest but most gay solution
	var controls:Controls = new Controls();
	var resetButton:MenuButton;
	var curAlt:Bool = false;

	override public function create()
	{
		resetButton = new MenuButton(0, 0, "RESET");
		resetButton.setColorTransform(0, 0, 0, 1, 255, 255, 255, 0);
		resetButton.getCallback = function()
		{
			Controls.INPUTS = [
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
			loadText();
		}
		resetButton.scale.set(2, 2);
		resetButton.updateHitbox();
		resetButton.screenCenter(X);
		resetButton.y -= 400;
		add(resetButton);
		add(resetButton.label);
		var saveButton:MenuButton = new MenuButton(0, -100, "SAVE");
		saveButton.screenCenter(X);
		add(saveButton);
		add(saveButton.label);
		saveButton.getCallback = Settings.saveSettings;
		saveButton.setColorTransform(0, 0, 0, 1, 255, 255, 255, 0);
		loadText();
		super.create();
	}

	function loadText()
	{
		var lastY:Float = 100;
		var i:Int = 0;
		for (i in 0...keys.length)
		{
			keys[i].kill();
			remove(keys[i]);
			keys[i].destroy();
			keysAlt[i].kill();
			remove(keysAlt[i]);
			keysAlt[i].destroy();
			inputs[i].kill();
			remove(inputs[i]);
			inputs[i].destroy();
		}
		inputs = [];
		keys = [];
		keysAlt = [];
		for (shit in inputsRaw)
		{
			var inputText:FlxText = new FlxText(0, lastY, 0, shit + ":", 72);
			inputText.x = FlxG.width * 0.167;
			for (j in 0...2)
			{
				var keyText:FlxText = new FlxText(0, lastY, 0, Misc.keyMap[Controls.INPUTS[cast(shit, Input)][j]], 60);
				keyText.font = AssetPaths.Crang__ttf;
				keyText.x = inputText.x + FlxG.width * (0.25 + 0.25 * j);
				keyText.ID = i;
				add(keyText);
				j == 0 ? keys.push(keyText) : keysAlt.push(keyText);
			}
			lastY += inputText.height;
			inputText.font = AssetPaths.easvhs__ttf;
			add(inputText);
			inputs.push(inputText);
			i++;
		}
		changeSelection(0);
	}

	function changeAlt()
	{
		curAlt = !curAlt;
		if (curAlt)
		{
			keysAlt[curSelected].color = FlxColor.RED;
			keys[curSelected].color = FlxColor.WHITE;
		}
		else
		{
			keysAlt[curSelected].color = FlxColor.WHITE;
			keys[curSelected].color = FlxColor.RED;
		}
	}

	var rebindingKey:Bool = false;
	var time:Float = 0;
	var backTimer:Float = 0;

	override public function update(elapsed:Float)
	{
		time += elapsed;
		if (!rebindingKey)
		{
			if (FlxG.mouse.wheel < 0 || controls.getJustPressed(DOWN))
				changeSelection(1);
			else if (FlxG.mouse.wheel > 0 || controls.getJustPressed(UP))
				changeSelection(-1);
			else if (controls.getJustPressed(RIGHT) || controls.getJustPressed(LEFT))
				changeAlt();
			else if (controls.getJustPressed(BACK))
			{
				Settings.saveSettings();
				Settings.loadSettings();
				FlxG.switchState(new OptionsState(OptionsState.targetState, OptionsState.args));
			}
			if (controls.getReleased(ACCEPT))
			{
				time = 0;
				rebindingKey = true;
			}
		}
		else
		{
			controls.getPressed(BACK) ? backTimer += elapsed : backTimer = 0;
			curAlt ? keysAlt[curSelected].alpha = Math.abs(Math.sin(time * 4)) : keys[curSelected].alpha = Math.abs(Math.sin(time * 4));
			var key = FlxG.keys.firstJustReleased();
			if (key > -1)
			{
				var keysArray = Controls.INPUTS.get(cast(inputsRaw[curSelected], Input));
				var keysDupe = keysArray.copy();
				keysArray[curAlt ? 1 : 0] = key;
				if (keysArray[0] != keysArray[1])
				{
					Controls.INPUTS.set(cast(inputsRaw[curSelected], Input), keysArray);
					rebindingKey = false;
					loadText();
				}
				else
				{
					Controls.INPUTS.set(cast(inputsRaw[curSelected], Input), keysDupe);
					FlxG.stage.window.alert("CANNOT SET TWO IDENTICAL KEYBINDS", "ERROR");
				}
			}
			else if (backTimer > 2)
			{
				rebindingKey = false;
				loadText();
				backTimer = 0;
			}
		}
		super.update(elapsed);
	}

	var selectionTween:FlxTween;

	function changeSelection(change:Int = 0)
	{
		keys[curSelected].color = FlxColor.WHITE;
		keysAlt[curSelected].color = FlxColor.WHITE;
		curSelected += change;
		if (curSelected >= keys.length)
			curSelected = 0;
		else if (curSelected < 0)
			curSelected = keys.length - 1;
		curAlt ? keysAlt[curSelected].color = FlxColor.RED : keys[curSelected].color = FlxColor.RED;
		selectionTween?.cancel();
		selectionTween?.destroy();
		selectionTween = FlxTween.tween(FlxG.camera.scroll, {y: keys[curSelected].y - FlxG.height / 2}, 0.2, {ease: FlxEase.quadOut});
	}
}
