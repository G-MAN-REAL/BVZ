package;

import Misc.Hurtbox;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import lime.math.Vector2;

class Projectile extends FlxSprite
{
	var parent:FlxSprite;

	public var hurtbox:Hurtbox;

	var group:FlxTypedGroup<Projectile>;

	public function new(parent:FlxSprite, SPEEDX:Int, SPEEDY:Int, group:FlxTypedGroup<Projectile>)
	{
		super();
		makeGraphic(2, 1, FlxColor.WHITE);
		velocity.set(SPEEDX, SPEEDY);
		setPosition(parent.x, parent.y);
		this.parent = parent;
		this.group = group;
		group.add(this);
	}

	override function destroy()
	{
		if (hurtbox != null && hurtbox.shape != null)
			hurtbox.shape.put();
		hurtbox = null;
		kill();
		group.remove(this);
		super.destroy();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (hurtbox != null)
		{
			if (hurtbox.lifespan <= 0)
			{
				destroy();
				return;
			}
			else if (hurtbox.attached)
				hurtbox.shape.set_local_position(new echo.math.Vector2(getMidpoint().x, getMidpoint().y));
			hurtbox.lifespan -= 120 * Reflect.getProperty(FlxG.state, "updateFrac") / FlxG.updateFramerate;
		}
	}
}
