package substates;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.nape.FlxNapeSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import states.BaseGameState;
import states.HubState;

class CharacterSelectSubstate extends FlxSubState
{
	final characters:Array<String> = [
		AssetPaths.albusSelect__png,
		AssetPaths.mahatmaSelect__png,
		AssetPaths.hipswitchSelect__png
	];
	final characterNames:Array<String> = ["ALBUS", "MAHATMA", "HIPSWITCH"];
	var characterGroup:FlxTypedGroup<FlxSprite>;
	var attila:FlxSprite;
	var attilaFlicker:FlxFlicker;
	var flicker:FlxFlicker;

	override public function create()
	{
		attila = new FlxSprite(0, 0, AssetPaths.mahatmaSelect2__png);
		add(attila);
		characterGroup = new FlxTypedGroup<FlxSprite>();
		add(characterGroup);
		var lastX:Float = 0;
		for (i in 0...characters.length)
		{
			var character = characters[i];
			var fooSpr:FlxSprite = new FlxSprite(lastX, FlxG.height + 100).loadGraphic(character);
			fooSpr.updateHitbox();
			lastX += fooSpr.width;
			fooSpr.ID = i;
			characterGroup.add(fooSpr);
		}
	}

	var time:Float = 0;
	var newTime:Float = 0;
	var doingMove = false;
	var goingBack:Bool = false;

	override public function update(elapsed:Float)
	{
		time += elapsed;
		attila.setPosition(characterGroup.members[1].x, characterGroup.members[1].y);
		if (FlxG.mouse.justPressedRight)
			goingBack = true;
		if (goingBack)
		{
			if (doingMove)
			{
				flicker?.stop();
				flicker = null;
				attilaFlicker?.stop();
				attilaFlicker = null;
				doingMove = false;
				goingBack = false;
			}
			else
			{
				newTime += elapsed;
				characterGroup.forEach(function(spr:FlxSprite)
				{
					spr.y = FlxMath.lerp(spr.y, FlxG.height + 100, Misc.wrap(newTime - spr.ID / 8, 0, 1));
					if (Misc.wrap(newTime - 2 / 8, 0, 1) == 1)
						close();
				});
			}
		}
		if (!doingMove && !goingBack)
		{
			characterGroup.forEach(function(spr:FlxSprite)
			{
				spr.y = FlxMath.lerp(spr.y, FlxG.height - 640, Misc.wrap(time - spr.ID / 8, 0, 1));
				if (FlxG.mouse.overlaps(spr))
				{
					spr.color = FlxColor.WHITE;
					if (spr.ID == 1)
						spr.alpha -= 0.2 * elapsed;
					if (FlxG.mouse.justPressed)
					{
						doingMove = true;
						if (spr.ID == 1)
							attilaFlicker = FlxFlicker.flicker(attila, 1, 0.04, true, true);
						flicker = FlxFlicker.flicker(spr, 1, 0.04, true, true, function(flicker:FlxFlicker)
						{
							var integer = FlxG.save.data.lastLevel != null ? FlxG.save.data.lastLevel : Misc.levelNum;
							trace(integer, FlxG.save.data.lastLevel);
							FlxG.switchState(new HubState(characterNames[spr.ID], "hub.tmx"));
						});
					}
				}
				else
				{
					spr.color = FlxColor.GRAY;
					spr.alpha = 1;
				}
			});
		}
		super.update(elapsed);
	}
}
