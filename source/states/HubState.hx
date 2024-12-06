package states;

import echo.FlxEcho;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.tile.FlxTilemapExt;
import flixel.math.FlxPoint;
import flixel.tile.FlxTile;
import flixel.tile.FlxTilemap;
import flixel.util.FlxColor;
import playerstuff.*;

class HubState extends BaseGameState
{
	override public function create()
	{
		super.create();
		FlxG.sound.playMusic(AssetPaths.Prism__ogg);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
