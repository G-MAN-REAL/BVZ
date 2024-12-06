package;

import echo.math.Vector2;
import echo.shape.Rect;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import nape.phys.Body;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.shape.Shape;

typedef Hurtbox =
{
	var lifespan:Float;
	var attached:Bool;
	var shape:echo.Shape;
	var damage:Int;
	var knockback:FlxPoint;
	var stuntime:Int;
	var cooldown:Float;
	@:optional var poisonous:Int;
	@:optional var fire:Int;
	@:optional var frozen:Int;
	@:optional var thunder:Int;
}

class Misc
{
	public static var keyMap = FlxKey.toStringMap;
	public static var maps:Array<String> = ["map1", "map2", "map3"];
	public static var levelNum:Int = 0;
	public static var coins:Int = 0;

	public static function wrap(a:Float, min:Float, max:Float):Float
	{
		if (a > max)
			a = max;
		else if (a < min)
			a = min;
		return a;
	}

	public static function initKeyMap()
	{
		keyMap.set(FlxKey.NONE, "NONE");
	}

	public static function cirlceIntersectsRect(circle:Circle, rect:FlxRect):Bool
	{
		var circleDistance = FlxPoint.get(Math.abs(circle.worldCOM.x - rect.x), Math.abs(circle.worldCOM.y - rect.y));
		if (circleDistance.x > (rect.width / 2 + circle.radius))
		{
			return false;
		}
		if (circleDistance.y > (rect.height / 2 + circle.radius))
		{
			return false;
		}

		if (circleDistance.x <= (rect.width / 2))
		{
			return true;
		}
		if (circleDistance.y <= (rect.height / 2))
		{
			return true;
		}

		var cornerDistance_sq = (circleDistance.x
			- rect.width / 2) * (circleDistance.x - rect.width / 2)
			+ (circleDistance.y - rect.height / 2) * (circleDistance.y - rect.height / 2);

		circleDistance.put();
		rect.put();

		return (cornerDistance_sq <= (circle.radius * circle.radius));
	}

	public static function convertToEcho(array:Array<FlxPoint>):Array<Vector2>
	{
		return array.map((point:FlxPoint) ->
		{
			return new Vector2(Std.int(point.x), Std.int(point.y));
		});
	}

	public static function checkHurtbox(shape:echo.Shape, rect:echo.Shape):Bool
	{
		if (Std.isOfType(shape, echo.shape.Circle))
		{
			final intersection = cast(shape, echo.shape.Circle).collides(cast(rect, Rect));
			if (intersection != null)
			{
				intersection.put();
				return true;
			}
			else
				return false;
		}
		else if (Std.isOfType(shape, Rect))
		{
			final intersection = cast(shape, echo.shape.Rect).collides(cast(rect, Rect));
			if (intersection != null)
			{
				intersection.put();
				return true;
			}
			else
				return false;
		}
		return return false;
	}
}
