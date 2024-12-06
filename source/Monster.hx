package;

import AttachedObjects.AttachedSprite;
import Misc.Hurtbox;
import echo.shape.Rect;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.nape.FlxNapeSprite;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxVelocity;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.shape.Polygon;

using echo.FlxEcho;

class Monster extends BaseSprite
{
	var brain:FSM;
	var idleTimer:Float;
	var moveDirection:Float;
	var WALK_SPEED:Int = 20;
	var CHASE_SPEED:Int = 400;
	var JUMP_HEIGHT:Float = -400;

	public var seesPlayer:Bool;
	public var playerPosition:FlxPoint;
	public var alerted:Bool = true;

	var surprisedTimer:Float = 0;
	var alertTimer:Float = 10;

	public function new(map:TiledLevel)
	{
		super(map);
		this.map = map;
		makeGraphic(32, 64, FlxColor.GRAY);
		acceleration.y = GRAVITY;
		health = maxHealth = 30;
		drag.set(500, 0);
		brain = new FSM(idle);
		idleTimer = 0;
		playerPosition = FlxPoint.get();
		var exclamation = new AttachedSprite(this, AssetPaths.surprise__png);
		HUDMap.set("exclamation", exclamation);
		facing = LEFT;
	}

	override public function kill()
	{
		killHUD();
		if (alive)
		{
			alive = false;
			this.get_body().rotation = 90;
			var point = FlxPoint.get(width, height);
			point.rotateByDegrees(angle);
			// width = Math.abs(point.x);
			// height = Math.abs(point.y);
			// offset.x = point.x / 4;
			// offset.y = point.y / 2;
			point.put();
		}
	}

	override function calcSurprised():Bool
	{
		if (!seesPlayer)
			brain.activeState = surprised;
		return brain.activeState == surprised && !alerted;
	}

	function surprised(elapsed:Float)
	{
		surprisedTimer += elapsed;
		if (surprisedTimer >= 0.25)
		{
			brain.activeState = chase;
			surprisedTimer = 0;
		}
	}

	function idle(elapsed:Float)
	{
		if (seesPlayer)
		{
			brain.activeState = chase;
		}
		else if (calcWalkpath())
		{
			if (!paralyzed)
				velocity.set(WALK_SPEED * (alertTimer > 0 ? 4 : 1) * (facing == LEFT ? -1 : 1), velocity.y);
		}
		else
		{
			if (!paralyzed)
			{
				facing = facing == LEFT ? RIGHT : LEFT;
				velocity.set(WALK_SPEED * (alertTimer > 0 ? 4 : 1) * (facing == LEFT ? -1 : 1), velocity.y);
			}
		}
	}

	function calcWalkpath()
	{
		@:privateAccess {
			var ray:Bool = true;
			final layer = map.collidableTileLayers[0];
			final value1 = layer._data[layer.getTileIndexByCoords(FlxPoint.weak(x + width + 1, y + height / 2))];
			final value2 = layer._data[layer.getTileIndexByCoords(FlxPoint.weak(x - 1, y + height / 2))];
			if (value2 != 0 && value2 != -1 && value1 != 0 && value1 != -1 && touching.has(FLOOR))
				velocity.y = JUMP_HEIGHT;

			if (facing == RIGHT)
			{
				ray = (value1 == 0 || value1 == -1);
			}
			else if (facing == LEFT)
			{
				ray = (value2 == 0 || value2 == -1);
			}
			if (x == layer.x + 1
				|| x == layer.scaledWidth - width - 1
				|| (facing == LEFT ? layer._data[layer.getTileIndexByCoords(FlxPoint.weak(x - 1,
					y + height + 1))] == 0 : layer._data[layer.getTileIndexByCoords(FlxPoint.weak(x + width + 1, y + height + 1))] == 0))
				ray = false; // world borders
			return ray;
		}
	}

	function chase(elapsed:Float)
	{
		if (!seesPlayer)
		{
			brain.activeState = idle;
		}
		else if (!paralyzed)
		{
			final ang = FlxAngle.angleBetweenPoint(this, playerPosition);
			final dist = FlxPoint.weak(Math.abs(getMidpoint().x - playerPosition.x), getMidpoint().y - playerPosition.y);
			final velocityX = Math.cos(ang) * CHASE_SPEED;
			final velocityY = jump(ang, dist);
			velocity.set(dist.x > width ? velocityX : 0, velocityY);
			if (dist.x <= width && Math.abs(dist.y) <= height)
			{
				brain.activeState = attack;
			}
			dist.put();
		}
	}

	function attack(elapsed:Float)
	{
		if (Math.abs(getMidpoint().x - playerPosition.x) > width || Math.abs(getMidpoint().y - playerPosition.y) > height || cooldown > 0)
			brain.activeState = idle;
		else
		{
			hurtbox = {
				stuntime: 200,
				shape: Rect.get(x, y + height / 2, 100, 100),
				lifespan: 2,
				damage: 2,
				knockback: FlxPoint.get(100, -100),
				attached: true,
				cooldown: 1
			};
		}
	}

	function jump(ang:Float, dist:FlxPoint):Float
	{
		ang = Math.abs(ang);
		if (dist.y > 0 && touching.has(FLOOR)) // on the floor
			return JUMP_HEIGHT;
		return velocity.y;
	}

	public function alert()
	{
		if (playerPosition.x > getMidpoint().x)
			facing = RIGHT;
		else if (playerPosition.x < getMidpoint().x)
			facing = LEFT;
		alerted = true;
		alertTimer = 10;
	}

	override function hurt(damage:Float)
	{
		super.hurt(damage);
		alert();
	}

	function checkEnemyVision()
	{
		if ((facing == LEFT && map.state.player.x <= x) || (facing == RIGHT && map.state.player.x >= x) || alerted)
		{
			if (map.collidableTileLayers[0].ray(getMidpoint(), map.state.player.getMidpoint()))
			{
				if (!seesPlayer && alertTimer <= 0)
					brain.activeState = surprised;
				alert();
				seesPlayer = true;
			}
			else
			{
				seesPlayer = false;
			}
		}
		else
		{
			seesPlayer = false;
		}
	}

	override function update(elapsed:Float)
	{
		if (alive)
		{
			invulnerability -= elapsed;
			if (invulnerability < 0)
				invulnerability = 0;
			HUDMap["exclamation"].visible = brain.activeState == surprised;
			HUDMap["exclamation"].xOffset = facing == RIGHT ? width : -10;
			HUDMap["exclamation"].yOffset = -HUDMap["exclamation"].height;
			playerPosition = map.state.player.getMidpoint();
			if (!stunned)
			{
				checkEnemyVision();
				brain.update(elapsed);
			}
			if (alerted)
			{
				if (!seesPlayer)
				{
					alertTimer -= elapsed;
					if (alertTimer <= 0)
						alerted = false;
				}
				else
					alertTimer = 10;
			}
			register_hurtboxes();
		}
		super.update(elapsed);
	}
}
