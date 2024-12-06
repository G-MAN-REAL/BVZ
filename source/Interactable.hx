package;

import Controls.Input;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import playerstuff.Player;

class Interactable extends FlxTypedGroup<Dynamic>
{
	var oneshot:Bool = true;
	var fired:Bool = false;

	public var onInteract:Void->Void;

	public var usesInteractBar:Bool = true;

	public var interactBar:FlxSprite;
	public var interactText:FlxText;
	public var mainObject:FlxSprite;
	public var interactTimeTotal:Float = 100;

	public var player:Player;

	public var chestLootSFX:FlxSound;

	public function new()
	{
		super();
		mainObject = new FlxSprite().loadGraphic(AssetPaths.chest__png);
		interactBar = new FlxSprite().makeGraphic(1, 10, FlxColor.LIME);
		interactBar.scale.set(0, 1);
		interactText = new FlxText("PRESS " + Controls.INPUTS[Input.INTERACT][0] + " OR " + Controls.INPUTS[Input.INTERACT][1]);
		interactText.setFormat(16, FlxColor.WHITE, null);
		chestLootSFX = new FlxSound().loadEmbedded(AssetPaths.lootchest__ogg);
		FlxG.state.add(chestLootSFX);
	}

	var interactTime:Float = 0;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (player != null)
		{
			interactText.setPosition(mainObject.x - (interactText.width - mainObject.width) / 2, mainObject.y - interactText.height - 10);
			interactBar.setPosition(mainObject.x - (interactBar.width - mainObject.width) / 2, mainObject.y - interactBar.height - 50);
			if (FlxMath.distanceBetween(mainObject, player) < mainObject.width && player.controls.getPressed(INTERACT) && !fired)
			{
				if (interactTime < interactTimeTotal)
				{
					interactTime += elapsed * 60;
				}
				else
				{
					if (oneshot && !fired || !oneshot)
					{
						fired = true;
						if (onInteract != null)
							onInteract();
					}
				}
			}
			else
			{
				interactTime = 0;
			}
			if (usesInteractBar)
				interactBar.scale.x = interactTime / interactTimeTotal * 100;
			if (fired)
			{
				interactTime = 0;
				interactText.visible = false;
			}
		}
	}

	public function init_objects()
	{
		FlxG.state.add(this);
		add(mainObject);
		add(interactText);
		if (usesInteractBar)
			add(interactBar);
	}
}
