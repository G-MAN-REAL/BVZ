package playerstuff;

import echo.math.Vector2;
import echo.shape.Rect;
import flixel.FlxG;
import flixel.addons.effects.FlxTrail;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.tile.FlxTilemap;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.shape.Circle;
import nape.shape.Polygon;
import playerstuff.Player;

class Hipswitch extends Player
{
	var thunderSFX:FlxSound;
	var iceSFX:FlxSound;
	var fireSFX:FlxSound;
	var hitSFX:Array<FlxSound> = [];

	public var trail:FlxTrail;

	var ultTimer:Null<Float> = null;

	public function new(mapTiles:TiledLevel)
	{
		super(mapTiles);
		maxJumps = 2;
		name = 'Hipswitch';
		thunderSFX = new FlxSound().loadEmbedded(AssetPaths.thundershot__ogg);
		iceSFX = new FlxSound().loadEmbedded(AssetPaths.icehit__ogg);
		fireSFX = new FlxSound().loadEmbedded(AssetPaths.fireshot__ogg);
		FlxG.sound.list.add(fireSFX);
		FlxG.sound.list.add(thunderSFX);
		FlxG.sound.list.add(iceSFX);
		trail = new FlxTrail(this);
		FlxG.state.add(trail);
		trail.visible = false;
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
					lifespan: 10,
					attached: true,
					shape: echo.shape.Circle.get(realX, y + height / 2, 16),
					damage: 1,
					knockback: FlxPoint.get(100 * kbMod, 0),
					stuntime: 1000,
					cooldown: 0
				}
			}
			else if (controls.getJustPressed(ATTACK1))
			{
				var projectile = new Projectile(this, 2000 * kbMod, 100, map.state.projectiles);
				projectile.hurtbox = {
					lifespan: 10,
					attached: true,
					shape: Rect.get(projectile.x, projectile.y, 2, 1),
					damage: 1,
					knockback: FlxPoint.get(100 * kbMod, 0),
					stuntime: 1000,
					fire: 60,
					frozen: 0,
					thunder: 0,
					cooldown: 0
				}
			}
			else if (controls.getJustPressed(ATTACK2))
			{
				var projectile = new Projectile(this, 2000 * kbMod, 100, map.state.projectiles);
				projectile.hurtbox = {
					lifespan: 10,
					attached: true,
					shape: Rect.get(projectile.x, projectile.y, 2, 1),
					damage: 1,
					knockback: FlxPoint.get(100 * kbMod, 0),
					stuntime: 1000,
					fire: 0,
					frozen: 120,
					thunder: 0,
					cooldown: 0
				}
				iceSFX.play(true);
			}
			else if (controls.getJustPressed(ATTACK3))
			{
				var projectile = new Projectile(this, 2000 * kbMod, 100, map.state.projectiles);
				projectile.hurtbox = {
					lifespan: 10,
					attached: true,
					shape: Rect.get(projectile.x, projectile.y, 2, 1),
					damage: 1,
					knockback: FlxPoint.get(100 * kbMod, 0),
					stuntime: 1000,
					fire: 0,
					frozen: 0,
					thunder: 3,
					cooldown: 0
				}
				thunderSFX.play(true);
			}
			else if (controls.getJustPressed(ULT))
			{
				if (ultCount >= ultMax)
				{
					ultCount = 0;
					ultTimer = 5;
					trail.visible = true;
					map.state.updateFrac = 0.25;
					for (sound in FlxG.sound.defaultMusicGroup.sounds)
					{
						sound.pitch = 0.5;
					}
					for (sound in FlxG.sound.list)
					{
						sound.pitch = 0.5;
					}
				}
			}
		}
		if (ultTimer > 0)
		{
			ultTimer -= 1 / FlxG.updateFramerate;
		}
		else if (ultTimer <= 0)
		{
			trail.visible = false;
			ultTimer = null;
			map.state.updateFrac = 1;
			for (sound in FlxG.sound.defaultMusicGroup.sounds)
				sound.pitch = 1;
			for (sound in FlxG.sound.list)
			{
				sound.pitch = 1;
			}
		}
	}
}
