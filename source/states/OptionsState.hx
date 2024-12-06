package states;

import flixel.FlxG;
import flixel.FlxState;

class OptionsState extends FlxState
{
	var options:Array<String> = ["PREFERENCES", "CONTROLS"];
	var optionsButtons:Array<MenuButton> = [];
	var controls:Controls = new Controls();

	public static var args:Array<Dynamic>;
	public static var targetState:FlxState;

	public function new(targetState:FlxState, args:Array<Dynamic>)
	{
		super();
		OptionsState.args = args;
		OptionsState.targetState = targetState;
	}

	override public function create()
	{
		for (i in 0...options.length)
		{
			var menuButton = new MenuButton(0, 0, options[i]);
			add(menuButton);
			add(menuButton.label);
			menuButton.scale.set(2, 2);
			menuButton.updateHitbox();
			menuButton.screenCenter(Y);
			menuButton.x = (FlxG.width - menuButton.width) / 2 - menuButton.width * 0.25 * options.length + menuButton.width * i;
			menuButton.label.setFormat(null, 36);
			menuButton.setColorTransform(1, 1, 1, 1, 255, 255, 255, 0);
			optionsButtons.push(menuButton);
			switch (i)
			{
				case 0:
					menuButton.getCallback = function()
					{
						FlxG.switchState(new PreferencesState());
					};
				case 1:
					menuButton.getCallback = function()
					{
						FlxG.switchState(new ControlsState());
					};
			}
			super.create();
		}
	}

	override public function update(elapsed:Float)
	{
		if (controls.getJustPressed(BACK))
			FlxG.switchState(Type.createInstance(Type.getClass(targetState), args));
		super.update(elapsed);
	}
}
