package;

import echo.shape.Rect;
import flixel.FlxG;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxVelocity;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxTimer;
import haxe.Timer;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.shape.Polygon;

class Wolf extends Monster
{
	var damageModifier:Int = 1;

	public function new(map)
	{
		super(map);
		makeGraphic(64, 32, FlxColor.GRAY);
		health = maxHealth = 15;
		WALK_SPEED = 20;
		CHASE_SPEED = 600;
		JUMP_HEIGHT = -600;
		name = 'Wolf';
	}

	override public function kill()
	{
		killHUD();
		if (alive)
		{
			alive = false;
			makeGraphic(64, 16, FlxColor.GRAY);
		}
	}

	override function chase(elapsed:Float)
	{
		if (!seesPlayer)
		{
			brain.activeState = idle;
		}
		else if (!paralyzed)
		{
			final ang = FlxAngle.angleBetweenPoint(this, playerPosition);
			final dist = FlxPoint.weak(Math.abs(getMidpoint().x - playerPosition.x), getMidpoint().y - playerPosition.y);
			final distR = getMidpoint().distanceTo(playerPosition);
			if (distR < 200 && distR > 100 && FlxG.random.bool(1) && cooldown <= 0)
			{
				brain.activeState = specialAttack;
			}
			else
			{
				final velocityX = Math.cos(ang) * CHASE_SPEED;
				final velocityY = jump(ang, dist);
				velocity.set(dist.x > width ? velocityX : 0, velocityY);
				if (dist.x <= width && Math.abs(dist.y) <= height && cooldown <= 0)
					brain.activeState = attack;
				dist.put();
			}
		}
	}

	var attackTimer:Float = 0;

	function specialAttack(elapsed:Float)
	{
		if (Std.int(attackTimer) == 0 && velocity.x != 0)
			velocity.x = FlxMath.lerp(velocity.x, 0, 0.5);
		attackTimer += elapsed;
		if (Std.int(attackTimer) == 1)
		{
			if (touching.has(FLOOR))
			{
				final ang = FlxAngle.angleBetweenPoint(this, playerPosition);
				final dist = FlxPoint.weak(Math.abs(getMidpoint().x - playerPosition.x), getMidpoint().y - playerPosition.y);
				final velocityX = Math.cos(ang) * CHASE_SPEED;
				final velocityY = jump(ang, dist);
				velocity.set(dist.x > width ? velocityX : 0, velocityY);
				if (dist.x <= width && Math.abs(dist.y) <= height)
					brain.activeState = attack;
				dist.put();

				hurtbox = {
					stuntime: 200,
					shape: Rect.get(x, y + height / 2, 100, 100),
					lifespan: 10,
					damage: 8,
					knockback: FlxPoint.get(100, -100),
					attached: true,
					cooldown: 1
				};
			}
		}
		else if (Std.int(attackTimer) == 3 || x == map.state.player.x)
		{
			velocity.y = GRAVITY;
			attackTimer = 0;
			brain.activeState = chase;
		}
	}

	override function attack(elapsed:Float)
	{
		if (Math.abs(getMidpoint().x - playerPosition.x) > width || Math.abs(getMidpoint().y - playerPosition.y) > height)
			brain.activeState = idle;
		else
		{
			hurtbox = {
				stuntime: 200,
				shape: Rect.get(x, y + height / 2, 100, 100),
				lifespan: 2,
				damage: 4 * damageModifier,
				knockback: FlxPoint.get(100, -100),
				attached: true,
				cooldown: 1
			};
		}
		damageModifier = 1;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
