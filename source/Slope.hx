package;

import flixel.FlxSprite;
import flixel.util.FlxColor;

using echo.FlxEcho;

class Slope extends FlxSprite
{
	public var slopeVal:Int = 45;

	public function new(x:Float, y:Float, width:Int, height:Int, slopeVal:Int)
	{
		super(x, y);
		this.x = x;
		this.y = y;
		makeGraphic(width, height, FlxColor.TRANSPARENT);
		this.slopeVal = slopeVal;
	}
}
