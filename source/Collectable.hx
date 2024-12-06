package;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class Collectable extends FlxSprite
{
	public var lifespan:Float = 0;

	public function new()
	{
		super();
		makeGraphic(8, 8, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawCircle(this, 4, 4, 4, FlxColor.WHITE);
		acceleration.y = 1000;
		drag.set(500, 0);
	}

	override public function update(elapsed:Float)
	{
		lifespan += elapsed * 60;
		super.update(elapsed);
	}
}
