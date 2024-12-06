package substates;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.math.FlxAngle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import states.MainMenuState;
import states.OptionsState;

class PauseSubstate extends FlxSubState
{
	var options:Array<String> = ["RESUME", "RESET", "SETTINGS", "SAVE", "MENU"];
	var buttongroup:Array<MenuButton> = [];
	var curSelected:Int = 0;
	var controls:Controls;
	var args:Array<String>;

	public function new(camera:FlxCamera, args:Array<String>)
	{
		super();
		this.camera = camera;
		this.args = args;
	}

	override public function create()
	{
		var black:FlxSprite = new FlxSprite(0, -FlxG.height).makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		add(black);
		black.alpha = 0.5;
		FlxTween.tween(black, {alpha: 0.5, y: 0}, 0.5);
		var lastX:Float = 0;
		for (i in 0...options.length)
		{
			var button:MenuButton = new MenuButton(lastX, 0, options[i]);
			button.screenCenter();
			buttongroup.push(button);
			button.ID = i;
			add(button);
			add(button.label);
			button.camera = camera;
			switch (options[i])
			{
				case "RESUME":
					button.getCallback = function() close();
				case "RESET":
					button.getCallback = function() FlxG.switchState(Type.createInstance(Type.getClass(FlxG.state), args));
				case "MENU":
					button.getCallback = function() FlxG.switchState(new MainMenuState());
				case "SETTINGS":
					button.getCallback = function()
					{
						FlxG.switchState(new OptionsState(this._parentState, args));
					}
				case "SAVE":
					button.getCallback = function()
					{
						FlxG.save.data.lastLevel = Misc.levelNum;
						trace(Misc.levelNum);
						FlxG.save.flush();
					}
			}
		}
		controls = new Controls();
		changeSelection();
		super.create();
	}

	var doingMove = false;

	function changeSelection(change:Int = 0)
	{
		doingMove = true;
		curSelected += change;
		if (curSelected >= buttongroup.length)
			curSelected = 0;
		else if (curSelected < 0)
			curSelected = buttongroup.length - 1;
		for (button in buttongroup)
		{
			button.animation.play('static');
			var buttonX = (FlxG.width - button.frameWidth) / 2;
			var buttonY = (FlxG.height - button.frameHeight) / 2;
			buttonX += (curSelected - button.ID) * FlxG.width / options.length;
			if (buttonX > FlxG.width)
				buttonX -= FlxG.width;
			if (buttonX < 0)
				buttonX += FlxG.width;
			var fakeID = curSelected - button.ID;
			if (fakeID < 0)
				fakeID += options.length;
			buttonY -= Math.sin(FlxAngle.TO_RAD * fakeID * 180 / buttongroup.length) * 400;
			if (change == 3)
			{
				button.scale.set((200 + buttonY) / button.frameWidth, (200 + buttonY) / button.frameWidth);
				button.updateHitbox();
				button.setPosition(buttonX + button.offset.x, buttonY - button.offset.y + 100);
				doingMove = false;
			}
			else
			{
				final offsetX = -0.5 * (button.frameWidth * ((200 + buttonY) / button.frameWidth) - button.frameWidth);
				final offsetY = -0.5 * (button.frameHeight * ((200 + buttonY) / button.frameWidth) - button.frameHeight);
				FlxTween.tween(button, {x: buttonX + offsetX, y: buttonY + 100 - offsetY}, 0.5);
				FlxTween.tween(button.scale, {x: (200 + buttonY) / button.frameWidth, y: (200 + buttonY) / button.frameWidth}, 0.5, {
					onComplete: function(tween:FlxTween)
					{
						button.updateHitbox();
						doingMove = false;
					},
					onUpdate: function(tween:FlxTween)
					{
						button.updateHitbox();
					}
				});
			}
		}
	}

	override public function update(elapsed:Float)
	{
		if (!doingMove)
		{
			if (controls.getJustPressed(LEFT) || FlxG.mouse.wheel < 0)
				changeSelection(-1);
			else if (controls.getJustPressed(RIGHT) || FlxG.mouse.wheel > 0)
				changeSelection(1);
			else if (controls.getPressed(ACCEPT))
				buttongroup[curSelected].animation.play('press');
			if (controls.getReleased(ACCEPT))
			{
				buttongroup[curSelected].animation.play('static');
				switch (options[curSelected])
				{
					case "RESUME":
						close();
					case "RESET":
						FlxG.switchState(Type.createInstance(Type.getClass(FlxG.state), args));
					case "MENU":
						FlxG.switchState(new MainMenuState());
					case "SETTINGS":
						FlxG.switchState(new OptionsState(this._parentState, args));
					case "SAVE":
						FlxG.save.data.lastLevel = Misc.levelNum;
						trace(Misc.levelNum);
						FlxG.save.flush();
				}
			}
		}
		super.update(elapsed);
	}
}
