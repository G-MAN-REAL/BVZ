package substates;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import states.MainMenuState;
import states.OptionsState;

class GameOverSubstate extends FlxSubState
{
	var args:Array<String> = [];
	var setActiveLerps:Bool = false;
	var black:FlxSprite;
	var doorLeft:FlxSprite;
	var doorRight:FlxSprite;
	var options:Array<String> = ["RESTART", "MAIN MENU", "OPTIONS", "HUB"];
	var optionsGroup:Array<MenuButton> = [];
	var speedValue:Float = FlxG.random.int(96, 104); // start point
	var yValsToLerpTo:Array<Float> = [];

	public function new(camera:FlxCamera, args:Array<String>)
	{
		super();
		this.args = args;
		this.camera = camera;
	}

	override public function create()
	{
		black = new FlxSprite(0, -FlxG.height).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(black);
		doorLeft = new FlxSprite(-FlxG.width / 2, 0).makeGraphic(Std.int(FlxG.width / 10), FlxG.height, FlxColor.WHITE);
		doorRight = new FlxSprite(FlxG.width * 1.5, 0).makeGraphic(Std.int(FlxG.width / 10), FlxG.height, FlxColor.WHITE);
		add(doorLeft);
		add(doorRight);
		FlxG.sound.playMusic(AssetPaths.GameOver__ogg);
		for (i in 0...options.length)
		{
			final button = init_button(i);
			optionsGroup[i] = button;
			yValsToLerpTo[i] = button.y + FlxG.height;
			switch (i)
			{
				case 0:
					button.getCallback = () ->
					{
						FlxG.switchState(Type.createInstance(Type.getClass(FlxG.state), args));
					}
				case 1:
					button.getCallback = () ->
					{
						FlxG.switchState(new MainMenuState());
					}
				case 2:
					button.getCallback = () ->
					{
						FlxG.switchState(new OptionsState(this._parentState, args));
					}
				case 3:
					button.getCallback;
			}
		}
		FlxG.camera.flash(FlxColor.WHITE, 1, () ->
		{
			FlxTween.tween(black, {y: 0,}, 0.5, {
				onComplete: function(tween:FlxTween)
				{
					setActiveLerps = true;
				}
			});
		});
	}

	function init_button(i:Int = 0):MenuButton
	{
		final button = new MenuButton(0, 0, options[i]);
		button.ID = i;
		button.label.setFormat(button.label.font, 36, FlxColor.WHITE);
		button.scale.set(6 / options.length, 6 / options.length);
		button.updateHitbox();
		button.screenCenter(X);
		button.y = -FlxG.height + (FlxG.height / (options.length)) * button.ID + button.height / 4;
		add(button);
		add(button.label);
		button.camera = camera;
		return button;
	}

	var totalDistance:Float = 0;
	var multValue:Float = FlxG.height * FlxG.updateFramerate / 10;

	override public function update(elapsed:Float)
	{
		if (setActiveLerps)
		{
			black.y = FlxMath.lerp(black.y, 0, 0.5);
			if (Std.int(black.y) == 0)
			{
				black.y = 0;
				doorLeft.x = FlxMath.lerp(doorLeft.x, 0, 12 * elapsed);
				doorRight.x = FlxG.width * 9 / 10 - doorLeft.x;
			}
			for (button in optionsGroup)
			{
				if (totalDistance < FlxG.height)
				{
					button.y += multValue / FlxG.updateFramerate;
				}
			}
			if (totalDistance < FlxG.height)
			{
				totalDistance += multValue / FlxG.updateFramerate;
				multValue *= 0.9;
			}
		}
		super.update(elapsed);
	}
}
