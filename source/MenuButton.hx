package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;

class MenuButton extends FlxSprite
{
	public var getCallback:Void->Void;

	public var label:FlxText;

	public function new(x:Float, y:Float, text:String = '')
	{
		super(x, y);
		loadGraphic(AssetPaths.BASE_bpress__png, true, 360, 120);
		animation.add("static", [0], 24, true);
		animation.add("press", [1], 24, false);
		animation.play('static');
		label = new FlxText(0, 0, 0, text, 48);
		label.font = AssetPaths.chunkypixel__TTF;
		antialiasing = Settings.antialiasing;
	}

	private var selected:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.mouse.overlaps(this, camera))
		{
			if (FlxG.mouse.pressed)
			{
				animation.play('press');
				selected = true;
			}
		}
		if (FlxG.mouse.released && selected)
		{
			animation.play('static');
			if (getCallback != null)
				getCallback();
			selected = false;
		}
		if (label != null)
		{
			label.setPosition(x + (width - label.width) / 2, y + (height - label.height) / 2);
			label.scale.set(scale.x, scale.y);
			label.updateHitbox();
			label.scrollFactor.set(scrollFactor.x, scrollFactor.y);
		}
	}
}
