package playerstuff;

import echo.shape.Rect;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.tile.FlxTilemap;
import flixel.util.FlxDirection;
import flixel.util.FlxDirectionFlags;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.shape.Polygon;
import playerstuff.Player;

class Mahatma extends Player
{
	var knifeSFX:Array<FlxSound> = [
		new FlxSound().loadEmbedded(AssetPaths.knife__ogg),
		new FlxSound().loadEmbedded(AssetPaths.knife2__ogg),
		new FlxSound().loadEmbedded(AssetPaths.knife3__ogg)
	];

	public function new(mapTiles:TiledLevel)
	{
		super(mapTiles);
		maxJumps = 1;
		JUMPHEIGHT = -600;
		name = 'Mahatma';
		for (sfx in knifeSFX)
			FlxG.sound.list.add(sfx);
	}

	override function updateMovement()
	{
		var up:Bool = controls.getJustPressed(UP);
		var down:Bool = controls.getPressed(DOWN);
		var left:Bool = controls.getPressed(LEFT);
		var right:Bool = controls.getPressed(RIGHT);
		var grounded = touching.has(FlxDirectionFlags.FLOOR);
		var animToPlay:String = '';

		var ray:Bool = true;
		if (facing == RIGHT)
			ray = map.collidableTileLayers[0].ray(FlxPoint.weak(x + width, y + height / 2), FlxPoint.weak(x + width + 2, y + 10));
		else if (facing == LEFT)
			ray = map.collidableTileLayers[0].ray(FlxPoint.weak(x, y + height / 2), FlxPoint.weak(x - 2, y + 10));

		var wallkick:Bool = !ray && !grounded && velocity.y > 100;

		if (grounded)
		{
			jumps = maxJumps;
			animToPlay = 'idle';
		}
		else if (velocity.y > 0)
			animToPlay = ray ? 'fall' : 'wallkick';
		if (left && right)
			left = right = false;

		if (left || right || up || down)
		{
			if (left)
			{
				if (wallkick && facing == RIGHT)
				{
					velocity.set(-maxSpeed, JUMPHEIGHT * 3 / 4);
					animToPlay = 'jump';
					jumps--;
				}

				facing = FlxDirection.LEFT;
				flipX = true;
				velocity.x -= SPEED;
				if (!grounded)
				{
					velocity.x += SPEED * 0.5;
				}
				else if (down)
					velocity.x = 0;
				else
					animToPlay = 'lr';
			}
			else if (right)
			{
				if (wallkick && facing == LEFT)
				{
					velocity.set(maxSpeed, JUMPHEIGHT * 3 / 4);
					animToPlay = 'jump';
					jumps--;
				}
				facing = FlxDirection.RIGHT;
				flipX = false;
				velocity.x += SPEED;
				if (!grounded)
				{
					velocity.x -= SPEED * 0.5;
				}
				else if (down)
					velocity.x = 0;
				else
					animToPlay = 'lr';
			}
			if (up && jumps > 0)
			{
				if (grounded)
					jumping = true;
				velocity.y = JUMPHEIGHT / 2;
				jumps--;
				if (!grounded)
				{
					jumps--;
					velocity.y = JUMPHEIGHT;
				}
				animToPlay = jumps <= 0 ? 'doublejump' : 'jump';
			}
			else if (down)
				if (grounded)
					animToPlay = 'crouch';
				else
				{
					velocity.y += 100;
					if (controls.getPressed(DIVE))
					{
						animToPlay = 'dive';
						facing == RIGHT ? velocity.x += 50 : velocity.x -= 50;
					}
				}
		}
		if (Math.abs(velocity.x) > 50 && grounded)
			walk.play();
		if (jumping)
		{
			if (controls.getPressed(UP))
			{
				upTimer++;
				if (upTimer == jumpSquat)
				{
					velocity.y = JUMPHEIGHT;
					upTimer = 0;
					jumping = false;
				}
			}
		}
		if (controls.getReleased(UP))
		{
			jumping = false;
			upTimer = 0;
		}
		// if (animToPlay.length > 1 && animToPlay != animation.curAnim.name)
		// 	animation.play(animToPlay);
	}

	override function load_skills()
	{
		super.load_skills();
		var realX:Float = x;
		var kbMod:Int = -1;
		if (facing == RIGHT)
		{
			realX += width;
			kbMod = 1;
		}
		if (hurtbox == null)
		{
			if (controls.getJustPressed(MELEE))
			{
				hurtbox = {
					lifespan: 5,
					attached: true,
					shape: Rect.get(realX, y + height / 2, width, height),
					damage: 1,
					poisonous: 120,
					knockback: FlxPoint.get(100 * kbMod, 0),
					stuntime: 1000,
					cooldown: 0
				}
				knifeSFX[FlxG.random.int(0, knifeSFX.length - 1)].play(true);
			}
			else if (controls.getJustPressed(ATTACK1) || controls.getJustPressed(ATTACK2))
			{
				var projectile = new Projectile(this, 1000 * kbMod, controls.getJustPressed(ATTACK2) ? Std.int(-200 + velocity.y / 2) : 0,
					map.state.projectiles);
				projectile.hurtbox = {
					lifespan: 50,
					attached: true,
					shape: Rect.get(projectile.x, projectile.y, 2, 1),
					poisonous: 240,
					damage: 5,
					knockback: FlxPoint.get(100 * kbMod, 0),
					stuntime: 1000,
					cooldown: 0
				}
				if (controls.getJustPressed(ATTACK2))
					projectile.acceleration.y = GRAVITY;
			}
		}
	}
}
