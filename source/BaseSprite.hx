package;

import AttachedObjects.AttachedBar;
import AttachedObjects.AttachedSprite;
import AttachedObjects.AttachedText;
import Misc.Hurtbox;
import cpp.abi.Abi;
import echo.shape.Rect;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText.FlxTextAlign;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
import lime.math.Vector2;
import nape.geom.Vec2;
import nape.geom.Vec2List;
import nape.phys.Body;

using echo.FlxEcho;

class BaseSprite extends FlxSprite
{
	var GRAVITY:Int = 1000;
	var map:TiledLevel;

	public var slopes:FlxTilemap;

	public var stunned:Bool = false;

	public var poisoned:Array<Array<Null<Float>>> = [];
	public var frozen:Null<Float> = 0;
	public var burning:Array<Array<Null<Float>>> = [];
	public var thunder:Null<Float> = 0;

	public var burnDmg:Float = 0.1;
	public var poisonDmg:Float = 2;
	public var poisonStack:Int = 1;
	public var burningStack:Int = 1;

	var invulnerability:Float = 0;

	public var healthbar:AttachedBar;

	var healthbarText:AttachedText;
	var textBoolArray:Array<AttachedText> = [];

	var maxHealth:Int = 30;
	var slopeVal:Int = 0;

	public var hurtbox:Hurtbox;

	var cooldown:Float = 0;
	var name:String = 'Monster';
	var paralyzed:Bool = false;

	public var HUDMap:Map<String, AttachedSprite> = new Map<String, AttachedSprite>();

	public function new(map:TiledLevel)
	{
		super();
		this.add_body({});
		this.get_body().acceleration.y = GRAVITY;
		healthbar = new AttachedBar(x, y, this);
		healthbar.yOffset = -healthbar.height - 10;
		healthbarText = new AttachedText(this, "", AssetPaths.Crang__ttf);
		healthbarText.setFormat(AssetPaths.Crang__ttf, 16, healthbarText.color, FlxTextAlign.CENTER);
		if (!Settings.hideHealthText)
			map.state.add(healthbarText);
	}

	function killHUD()
	{
		healthbar.kill();
		healthbarText.kill();
		for (value in HUDMap)
			value.destroy();
	}

	function spawnDamageText(damage:Float)
	{
		if (textBoolArray.length < Std.int(Settings.damageTextNum.value) || Std.int(Settings.damageTextNum.value) < 0)
		{
			final newAttachedText = new AttachedText(this, Std.string(damage), AssetPaths.Crang__ttf);
			textBoolArray.push(newAttachedText);
			newAttachedText.setFormat(AssetPaths.Crang__ttf, 24);
			newAttachedText.xOffset = (this.width - newAttachedText.width) / 2;
			newAttachedText.yOffset = -newAttachedText.height;
			newAttachedText.color = 0xFF750404;
			map.state.add(newAttachedText);
			FlxTween.tween(newAttachedText, {yOffset: newAttachedText.yOffset - 10}, 0.5, {
				onComplete: (tween:FlxTween) ->
				{
					textBoolArray.remove(newAttachedText);
					newAttachedText.destroy();
				}
			});
		}
	}

	function register_hurtboxes()
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
			if (hurtbox.cooldown != -1)
			{
				cooldown = hurtbox.cooldown;
				hurtbox.cooldown = -1;
			}
			if (hurtbox.lifespan <= 0)
			{
				hurtbox.shape.put();
				hurtbox = null;
				return;
			}
			else if (hurtbox.attached)
			{
				hurtbox.shape.set_local_position(new echo.math.Vector2(realX, y + height / 2));
			}
			hurtbox.knockback.x = Math.abs(hurtbox.knockback.x) * kbMod;

			hurtbox.lifespan -= map.state.updateFrac * 120 / FlxG.updateFramerate;
		}
	}

	public function stun(time:Int = 0, damage:Float = 0, summonDamageText:Bool = true)
	{
		if (invulnerability <= 0)
		{
			stunned = true;
			haxe.Timer.delay(function()
			{
				stunned = false;
			}, time);
			if (summonDamageText && alive)
				spawnDamageText(damage);
			hurt(damage);
		}
	}

	public function calcSurprised()
	{
		return false;
	}

	public var bodyDefinesPosition:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (invulnerability <= 0)
		{
			for (i in 0...poisoned.length)
			{
				if (poisoned[i] != null)
				{
					if (poisoned[i][0] > 0)
					{
						poisoned[i][0] -= FlxMath.roundDecimal(elapsed * 60, 2);
						if (poisoned[i][0] % 60 == 0)
						{
							stun(0, poisoned[i][1]);
						}
						color = FlxColor.LIME;
					}
					else
						poisoned.remove(poisoned[i]);
				}
				else
					poisoned.remove(poisoned[i]);
			}
			for (i in 0...burning.length)
			{
				if (burning[i] != null)
				{
					if (burning[i][0] > 0)
					{
						if (frozen > 0)
							frozen = 0;
						burning[i][0] -= FlxMath.roundDecimal(elapsed * 60, 2);
						stun(0, burning[i][1], burning[i][0] % 30 == 0);
						color = FlxColor.RED;
					}
					else
						burning.remove(burning[i]);
				}
				else
					burning.remove(burning[i]);
			}
		}
		if (thunder > 0)
		{
			FlxObject.separate(map.collidableTileLayers[0], this);
			if (touching != NONE)
			{
				elasticity = 0.1;
				thunder--;
			}
		}
		else
		{
			elasticity = 0;
		}
		if (frozen > 0)
		{
			frozen -= FlxMath.roundDecimal(elapsed * 60, 2);
			color = FlxColor.CYAN;
		}
		if (cooldown > 0)
			cooldown -= FlxMath.roundDecimal(elapsed * 60, 2);
		if (health < 0)
			health = 0;
		paralyzed = !((frozen <= 0 || frozen == null) && (thunder <= 0 || thunder == null));
		healthbar.xOffset = (healthbar.width - width) / -2;
		healthbar.percent = health / maxHealth * 100;
		healthbarText.text = Std.int(health) + "/" + maxHealth + "\n" + name;
		healthbarText.xOffset = (this.width - healthbarText.width) / 2;
		healthbarText.yOffset = -healthbarText.height - healthbar.height - 16;
		flipX = facing == LEFT;
		this.get_body().load_options({
			shape: {
				width: this.width,
				height: this.height,
				offset_y: offset.y,
				offset_x: offset.x
			},
			x: getMidpoint().x,
			y: getMidpoint().y
		});
	}
}
