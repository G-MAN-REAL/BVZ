package states;

import Misc.Hurtbox;
import echo.FlxEcho;
import echo.util.SAT;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.nape.FlxNapeSpace;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import nape.geom.Vec2;
import nape.phys.InteractorList;
import nape.shape.Circle;
import nape.shape.ShapeType;
import openfl.filters.ShaderFilter;
import playerstuff.Albus;
import playerstuff.Hipswitch;
import playerstuff.Mahatma;
import playerstuff.Player;
import substates.GameOverSubstate;
import substates.PauseSubstate;
import tink.CoreApi.Ref;

class BaseGameState extends RhythmState
{
	var characterName:String;
	var mapName:String;

	public var player:Player;
	public var monsters:FlxTypedGroup<Monster>;
	public var HUDGroup:FlxTypedGroup<FlxSprite>;

	static final GRAVITY:Int = 1000;

	var walls:FlxGroup;
	var map:TiledLevel;
	var mapTiles:FlxTilemap;
	var arrayHurtbox:Array<Hurtbox> = [];
	var camHUD:FlxCamera;

	public var updateFrac:Float = 1;

	public var interactables:Array<Interactable> = [];
	public var collectables:FlxTypedGroup<Collectable>;

	public var exits:Array<FlxObject> = [];

	public var projectiles:FlxTypedGroup<Projectile>;

	var coinCounter:FlxText;
	var coinGrabSFX:FlxSound;

	public function new(characterName:String, mapName:String)
	{
		this.characterName = characterName;
		this.mapName = mapName;
		super();
	}

	override public function create()
	{
		FlxEcho.init({width: FlxG.width, height: FlxG.height, gravity_y: 0});
		camHUD = new FlxCamera();
		var camGame:FlxCamera = new FlxCamera();
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.setDefaultDrawTarget(camHUD, false);
		camHUD.bgColor = 0x0000000;

		monsters = new FlxTypedGroup<Monster>();
		projectiles = new FlxTypedGroup<Projectile>();
		collectables = new FlxTypedGroup<Collectable>();
		HUDGroup = new FlxTypedGroup<FlxSprite>();
		map = new TiledLevel("assets/data/levels/" + mapName, this);
		add(map.backgroundLayer);
		add(map.foregroundTiles);
		mapTiles = map.collidableTileLayers[0];
		mapTiles.follow();
		switch (characterName.toLowerCase())
		{
			case 'mahatma':
				player = new Mahatma(map);
			case 'albus':
				player = new Albus(map);
			case 'hipswitch':
				player = new Hipswitch(map);
		}
		add(player);
		for (interactable in interactables)
			interactable.player = player; // not proud of this
		if (!Settings.hideHealthbars)
			HUDGroup.add(player.healthbar);
		add(projectiles);
		player.x = map.START_POS.x;
		player.y = map.START_POS.y;
		FlxG.camera.follow(player);
		add(monsters);
		add(HUDGroup);
		add(collectables);

		coinCounter = new FlxText(10, 10, 0, "COINS: ", 32);
		coinCounter.setFormat(AssetPaths.Crang__ttf, 32);
		add(coinCounter);
		coinCounter.camera = camHUD;
		coinGrabSFX = new FlxSound().loadEmbedded(AssetPaths.coinpickup__ogg);

		walls = new FlxGroup();
		set_wall(mapTiles.x, mapTiles.y, 1, mapTiles.height);
		set_wall(mapTiles.x + mapTiles.width - 1, mapTiles.y, 1, mapTiles.height);
		add(walls);

		super.create();
	}

	var camTwn:FlxTween;

	inline function runCheckHurtbox(sprite:BaseSprite, hurtboxRef:Dynamic, sprite2:BaseSprite)
	{
		var hurtbox = hurtboxRef.hurtbox;
		if (hurtbox != null && sprite.alive)
		{
			if (Misc.checkHurtbox(hurtbox.shape, FlxEcho.get_body(sprite).shape))
			{
				if (sprite.calcSurprised() && sprite2.hurtbox != null)
				{
					sprite.stun(hurtbox.stuntime, hurtbox.damage * 2);
					var critical = new FlxSound().loadEmbedded(AssetPaths.critical__wav);
					critical.play();
				}
				else
				{
					sprite.stun(hurtbox.stuntime, hurtbox.damage);
				}
				sprite.velocity.set(hurtbox.knockback.x, hurtbox.knockback.y);
				var thunder = hurtbox.thunder;
				if (thunder > 0)
				{
					FlxG.camera.shake(0.01, 0.1);
					sprite.velocity.set(hurtbox.knockback.x / Math.abs(hurtbox.knockback.x) * thunder * 200, thunder * -200);
					sprite.thunder = thunder;
				}
				if (hurtbox.poisonous != null)
					sprite.poisoned.length < sprite2.poisonStack ? sprite.poisoned.push([hurtbox.poisonous, sprite2.poisonDmg]) : sprite.poisoned[0][0] = hurtbox.poisonous > sprite.poisoned[0][0] ? hurtbox.poisonous : sprite.poisoned[0][0];
				if (hurtbox.fire != null)
					sprite.burning.length < sprite2.burningStack ? sprite.burning.push([hurtbox.fire, sprite2.burnDmg]) : sprite.burning[0][0] = hurtbox.fire > sprite.burning[0][0] ? hurtbox.fire : sprite.burning[0][0];
				sprite.frozen = hurtbox.frozen;
				hurtboxRef.hurtbox = null;
			}
		}
	}

	override public function update(elapsed:Float)
	{
		if (player.controls.getJustPressed(PAUSE))
		{
			openSubState(new PauseSubstate(camHUD, [characterName, mapName]));
		}
		for (exit in exits)
		{
			if (player.overlaps(exit))
			{
				if (Std.isOfType(FlxG.state, HubState))
				{
					FlxG.switchState(new BaseGameState(characterName, "map" + (exit.ID + 1) + ".tmx"));
				}
				else
				{
					if (Misc.levelNum + 1 < Misc.maps.length)
					{
						Misc.levelNum++;
						FlxG.save.data.lastLevel = Misc.levelNum;
						FlxG.save.flush();
					}
					FlxG.switchState(new HubState(characterName, "hub.tmx"));
				}
			}
		}
		map.collideWithLevel(player);
		map.collideWithLevel(collectables);
		projectiles.forEach(function(projectile:Projectile)
		{
			map.collideWithLevel(projectile, (map, projectile) ->
			{
				projectile.destroy();
			});
		});
		monsters.forEach(function(monster:Monster)
		{
			if (monster.seesPlayer)
			{
				monsters.forEachAlive((monster2:Monster) ->
				{
					if (FlxMath.distanceToPoint(monster, monster2.getMidpoint()) < 200 && monster.alive && !monster2.alerted)
					{
						monster2.alert();
					}
				});
			}
			map.collideWithLevel(monster);
			if (mapTiles.ray(monster.getMidpoint(), player.getMidpoint()))
			{
				runCheckHurtbox(monster, player, player);
				runCheckHurtbox(player, monster, monster);
			}
			projectiles.forEach(function(projectile:Projectile)
			{
				if (projectile.overlaps(monster) && projectile.hurtbox != null)
				{
					runCheckHurtbox(monster, projectile, player);
					projectile.destroy();
				}
			});
		});
		collectables.forEachAlive((collectable:Collectable) ->
		{
			if (player.overlaps(collectable) && collectable.lifespan > 60)
			{
				collectables.remove(collectable);
				collectable.destroy();
				Misc.coins++;
				coinGrabSFX.play(true);
			}
		});
		FlxG.collide(player, walls);
		FlxG.collide(monsters, walls);
		FlxG.collide(collectables, walls);
		coinCounter.text = "COINS: " + Misc.coins;
		super.update(elapsed * updateFrac);
	}

	function set_wall(x:Float, y:Float, width:Float, height:Float)
	{
		var wall = new FlxObject(x, y, width, height);
		wall.immovable = true;
		walls.add(wall);
	}

	override function openSubState(state:FlxSubState)
	{
		super.openSubState(state);
		FlxEcho.updates = false;
	}

	override function closeSubState()
	{
		super.closeSubState();
		FlxEcho.updates = true;
	}
}
