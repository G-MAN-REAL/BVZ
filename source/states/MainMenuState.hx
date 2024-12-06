package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import substates.CharacterSelectSubstate;

class MainMenuState extends FlxState
{
	final buttons:Array<String> = ["OPTIONS", "PLAY", "CREDITS"];

	override public function create()
	{
		final background:FlxSprite = new FlxSprite(0, 0, AssetPaths.bg__png);
		background.updateHitbox();
		add(background);
		var lastX:Float = 75;
		for (i in 0...buttons.length)
		{
			var button:MenuButton = new MenuButton(lastX, 400, buttons[i]);
			button.setGraphicSize(Std.int(button.width * (1.6 - (0.2) * Math.abs(i - 1))));
			button.ID = i;
			button.updateHitbox();
			lastX += button.width + 100;
			add(button);
			add(button.label);
			button.getCallback = function()
			{
				switch (button.ID)
				{
					case 0:
						FlxG.switchState(new OptionsState(this, []));
					case 1:
						openSubState(new CharacterSelectSubstate());
					case 2:
				}
			}
		}

		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
