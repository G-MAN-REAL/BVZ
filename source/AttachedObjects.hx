package;

import flixel.FlxBasic.IFlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxAngle;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import openfl.Assets;

class AttachedSprite extends FlxSprite implements IAttachedSprite
{
	public var sprTracker:FlxObject;

	public var xOffset:Float = 0;

	public var yOffset:Float = 0;

	public function new(sprTracker:FlxObject, asset:FlxGraphicAsset)
	{
		super();
		this.sprTracker = sprTracker;
		loadGraphic(asset);
	};

	override public function update(elapsed:Float)
	{
		setPosition(sprTracker.x + xOffset, sprTracker.y + yOffset);
		super.update(elapsed);
	}
}

class AttachedText extends FlxText implements IAttachedSprite
{
	public var sprTracker:FlxObject;
	public var xOffset:Float = 0;
	public var yOffset:Float = 0;

	public function new(sprTracker:FlxSprite, text:String, font:String)
	{
		super();
		this.sprTracker = sprTracker;
		this.text = text;
		this.font = font;
	}

	override public function update(elapsed:Float)
	{
		setPosition(sprTracker.x + xOffset, sprTracker.y + yOffset);
		super.update(elapsed);
	}
}

class AttachedBar extends FlxSprite implements IAttachedSprite
{
	public var sprTracker:FlxObject;
	public var xOffset:Float = 0;
	public var yOffset:Float = 0;
	public var percent:Float = 100;

	private var oldPercent:Float = 100;

	public function new(x:Float, y:Float, sprTracker:FlxObject)
	{
		super(x, y);
		this.sprTracker = sprTracker;
		frames = FlxAtlasFrames.fromSparrow(AssetPaths.healthbar__png, Assets.getText(AssetPaths.healthbar__xml));
		animation.addByPrefix("0", "NO_health.png", 1, false);
		animation.addByPrefix("1", "1_health.png", 1, false);
		animation.addByPrefix("2", "2_health.png", 1, false);
		animation.addByPrefix("3", "3_health.png", 1, false);
		animation.addByPrefix("4", "4_health.png", 1, false);
		animation.addByPrefix("5", "FULL_health.png", 1, false);
		animation.play("5");
	}

	var u_time:Float = 0;
	var startShakeAndGlow:Bool = false;

	override public function update(elapsed:Float)
	{
		final animToPlay:String = Std.string(Math.ceil(percent / 20));
		if (percent != oldPercent)
			startShakeAndGlow = true;
		if (startShakeAndGlow)
		{
			if (u_time < 1)
			{
				u_time += elapsed;
				final value = Math.sin(u_time * 180 * FlxAngle.TO_RAD) * 255;
				setColorTransform(1, 1, 1, 1, value, value, value, 0);
			}
			else
			{
				u_time = 0;
				setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
				startShakeAndGlow = false;
			}
		}
		animation.play(animToPlay);
		setPosition(sprTracker.x + xOffset, sprTracker.y + yOffset);
		super.update(elapsed);
		oldPercent = percent;
	}
}

interface IAttachedSprite
{
	public var sprTracker:FlxObject;
	public var xOffset:Float;
	public var yOffset:Float;
}
