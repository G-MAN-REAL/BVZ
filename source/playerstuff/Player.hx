package playerstuff;

import AttachedObjects.AttachedText;
import Controls.Input;
import Misc.Hurtbox;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.nape.FlxNapeSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionSet;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxVelocity;
import flixel.sound.FlxSound;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;
import flixel.util.FlxDirectionFlags;
import lime.math.Vector2;
import nape.phys.Body;
import nape.shape.Polygon;
import openfl.Vector;
import openfl.display.Shape;
import openfl.utils.Assets;

class Player extends BaseSprite
{
	var SPEED:Int = 50;
	var JUMPHEIGHT = -500;
	var maxSpeed:Int = 500;
	var walk:FlxSound;
	var speedMod = 1;

	public var lastHealth:Float = 50;

	var animMap:Map<String, Vector2> = ["wallkick" => new Vector2(-20, 0), "crouch" => new Vector2(0, -20)];

	public var controls:Controls = new Controls();
	public var ultCount:Int = 10;
	public var ultMax:Int = 10;

	final jumpSquat = 3;
	var reachedApex:Null<Bool> = false;

	public function new(map:TiledLevel)
	{
		super(map);
		makeGraphic(32, 64, FlxColor.BLUE);
		// animation.addByPrefix("lr", "lr", 24, true);
		// animation.addByIndices("idle", "idle", [0, 1, 2, 3, 4, 5], '', 24, true);
		// animation.addByPrefix("idle2", "idle", 12, false);
		// animation.addByPrefix("fall", "fall", 24, false);
		// animation.addByPrefix("jump", "jump", 24, false);
		// animation.addByPrefix("crouch", "crouch", 12);
		// animation.addByPrefix("wallkick", "wallkick", 12, false);
		// animation.addByPrefix("dive", "dive", 24, false);
		// animation.addByIndices("die", "die", [0], '', 24, false);
		// animation.addByPrefix("dieFull", "die", 12, false);
		// animation.addByPrefix("hurt", "hurt", 24, false);
		// animation.addByPrefix("doublejump", "doublejump", 24, false);
		drag = FlxPoint.get(500, 0);
		acceleration.y = GRAVITY;
		// animation.play("idle");
		this.map = map;
		health = lastHealth = maxHealth = 50;
		burningStack = Upgrades.burningStack;
		poisonStack = Upgrades.poisonStack;
		burnDmg = Upgrades.damageTypes["fire"];
		poisonDmg = Upgrades.damageTypes["poison"];
		walk = new FlxSound().loadEmbedded(AssetPaths.walk__wav);
		FlxG.sound.list.add(walk);
		maxVelocity.set(maxSpeed, GRAVITY);
	}

	function doDeathSequence()
	{
		animation.play('die');
		@:privateAccess FlxG.state.openSubState(new substates.GameOverSubstate(map.state.camHUD, [map.state.characterName, map.state.mapName]));
		animation.finishCallback = function(name:String)
		{
			FlxObject.separateY(map.collidableTileLayers[0], this);
			if (touching.has(FlxDirectionFlags.FLOOR))
			{
				animation.play('dieFull');
				animation.finishCallback = null;
				// @:privateAccess FlxG.state.openSubState(new substates.GameOverSubstate(map.state.camHUD, [map.state.characterName, map.state.mapName]));
			}
			else
			{
				doDeathSequence();
			}
		}
	}

	override public function hurt(damage:Float)
	{
		health -= damage;
		invulnerability = 1;
		if (health <= 0)
		{
			doDeathSequence();
			killHUD();
			alive = false;
		}
		else
		{
			animation.play('hurt');
		}
	}

	function load_skills()
	{
		if (cooldown > 0)
			return;
	}

	override function update(elapsed:Float)
	{
		if (alive)
		{
			if (!stunned && !paralyzed)
				updateMovement();
			invulnerability -= elapsed;
			if (invulnerability <= 0)
			{
				alpha = 1;
				invulnerability = 0;
			}
			else if (invulnerability > 0)
				alpha = 0.5;
		}
		load_skills();
		register_hurtboxes();
		// animOffsets();

		super.update(elapsed);
	}

	var jumps:Int = 2;
	var maxJumps:Int = 2;
	var upTimer:Float = 0;
	var jumping:Bool = false;

	function updateMovement()
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
					velocity.y = JUMPHEIGHT;
					jumps--;
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
				upTimer += 60 / FlxG.updateFramerate;
				if (Std.int(upTimer) == jumpSquat)
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

	function animOffsets()
	{
		if (animMap[animation.curAnim.name] != null)
		{
			var offsetX = animMap[animation.curAnim.name].x;
			if (facing == LEFT)
				offsetX *= -1;
			var offsetY = animMap[animation.curAnim.name].y;
			offset.set(offsetX, offsetY);
		}
		else
			offset.set(0, 0);
	}

	override function register_hurtboxes()
	{
		var realX:Float = x;
		var kbMod:Int = -1;
		if (facing == RIGHT)
		{
			realX += width;
			kbMod = 1;
		}
		if (hurtbox != null)
		{
			if (hurtbox.lifespan <= 0)
			{
				hurtbox = null;
				return;
			}
			else if (hurtbox.attached)
			{
				hurtbox.shape.set_local_position(new echo.math.Vector2(realX, y + height / 2));
			}
			hurtbox.lifespan -= 120 * map.state.updateFrac / FlxG.updateFramerate;
		}
	}
}
