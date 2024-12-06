package;

import echo.Body;
import echo.Collisions;
import echo.Echo;
import echo.FlxEcho;
import echo.Line;
import echo.Physics;
import echo.Shape;
import echo.data.Data.Intersection;
import echo.data.Data.IntersectionData;
import echo.math.Vector2;
import echo.shape.Polygon;
import echo.shape.Rect;
import echo.util.SAT;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.editors.tiled.TiledImageLayer;
import flixel.addons.editors.tiled.TiledImageTile;
import flixel.addons.editors.tiled.TiledLayer.TiledLayerType;
import flixel.addons.editors.tiled.TiledMap.FlxTiledMapAsset;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.editors.tiled.TiledTilePropertySet;
import flixel.addons.editors.tiled.TiledTileSet;
import flixel.addons.tile.FlxTileSpecial;
import flixel.addons.tile.FlxTilemapExt;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import flixel.tweens.motion.LinearMotion;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
import haxe.io.Path;
import nape.shape.Edge;
import states.BaseGameState;

using echo.FlxEcho;

/**
 * @author Samuel Batista
 */
class TiledLevel extends TiledMap
{
	// For each "Tile Layer" in the map, you must define a "tileset" property which contains the name of a tile sheet image
	// used to draw tiles in that layer (without file extension). The image file must be located in the directory specified bellow.
	inline static var c_PATH_LEVEL_TILESHEETS = "assets/images/tiles/";

	// Array of tilemaps used for collision
	public var foregroundTiles:FlxGroup;
	public var objectsLayer:FlxGroup;
	public var backgroundLayer:FlxGroup;

	public var collidableTileLayers:Array<FlxTilemap>;

	// Sprites of images layers
	public var imagesLayer:FlxGroup;
	public var START_POS:flixel.math.FlxPoint;
	public var state:BaseGameState;
	public var collidableObjects:Array<FlxSprite> = [];

	public function new(tiledLevel:FlxTiledMapAsset, state:BaseGameState)
	{
		super(tiledLevel);

		imagesLayer = new FlxGroup();
		foregroundTiles = new FlxGroup();
		objectsLayer = new FlxGroup();
		backgroundLayer = new FlxGroup();
		this.state = state;

		loadImages();
		loadObjects();
		FlxG.worldBounds.set(0, 0, fullWidth, fullHeight);

		// Load Tile Maps
		for (layer in layers)
		{
			if (layer.type != TiledLayerType.TILE)
				continue;
			var tileLayer:TiledTileLayer = cast layer;

			var tileSheetName:String = tileLayer.properties.get("tileset");

			if (tileSheetName == null)
				throw "'tileset' property not defined for the '" + tileLayer.name + "' layer. Please add the property to the layer.";

			var tileSet:TiledTileSet = null;
			for (ts in tilesets)
			{
				if (ts.name == tileSheetName)
				{
					tileSet = ts;
					break;
				}
			}

			if (tileSet == null)
				throw "Tileset '"
					+ tileSheetName
					+ "' not found. Did you misspell the 'tilesheet' property in '"
					+ tileLayer.name
					+ "' layer?";

			var imagePath = new Path(tileSet.imageSource);
			var processedPath = c_PATH_LEVEL_TILESHEETS + imagePath.file + "." + imagePath.ext;

			// could be a regular FlxTilemap if there are no animated tiles
			var tilemap = new FlxTilemapExt();
			tilemap.loadMapFromArray(tileLayer.tileArray, width, height, processedPath, tileSet.tileWidth, tileSet.tileHeight, OFF, tileSet.firstGID, 1, 1);

			if (tileLayer.properties.contains("animated"))
			{
				var tileset = tilesets["level"];
				var specialTiles:Map<Int, TiledTilePropertySet> = new Map();
				for (tileProp in tileset.tileProps)
				{
					if (tileProp != null && tileProp.animationFrames.length > 0)
					{
						specialTiles[tileProp.tileID + tileset.firstGID] = tileProp;
					}
				}
				var tileLayer:TiledTileLayer = cast layer;
				tilemap.setSpecialTiles([
					for (tile in tileLayer.tiles)
						if (tile != null && specialTiles.exists(tile.tileID)) getAnimatedTile(specialTiles[tile.tileID], tileset) else null
				]);
			}
			if (tileLayer.properties.contains("nocollide"))
			{
				backgroundLayer.add(tilemap);
			}
			else
			{
				if (collidableTileLayers == null)
					collidableTileLayers = new Array<FlxTilemap>();

				foregroundTiles.add(tilemap);
				collidableTileLayers.push(tilemap);
			}
		}
	}

	function getAnimatedTile(props:TiledTilePropertySet, tileset:TiledTileSet):FlxTileSpecial
	{
		var special = new FlxTileSpecial(1, false, false, 0);
		var n:Int = props.animationFrames.length;
		var offset = Std.random(n);
		special.addAnimation([
			for (i in 0...n)
				props.animationFrames[(i + offset) % n].tileID + tileset.firstGID
		], (1000 / props.animationFrames[0].duration));
		return special;
	}

	public function loadObjects()
	{
		for (layer in layers)
		{
			if (layer.type != TiledLayerType.OBJECT)
				continue;
			var objectLayer:TiledObjectLayer = cast layer;

			// collection of images layer
			if (layer.name == "images")
			{
				for (o in objectLayer.objects)
				{
					loadImageObject(o);
				}
			}
			// objects layer
			if (layer.name == "objects")
			{
				for (o in objectLayer.objects)
				{
					loadObject(o, objectLayer, objectsLayer);
				}
			}
		}
	}

	function loadImageObject(object:TiledObject)
	{
		var tilesImageCollection:TiledTileSet = this.getTileSet("imageCollection");
		var tileImagesSource:TiledImageTile = tilesImageCollection.getImageSourceByGid(object.gid);

		// decorative sprites
		var levelsDir:String = c_PATH_LEVEL_TILESHEETS;

		var decoSprite:FlxSprite = new FlxSprite(0, 0, levelsDir + tileImagesSource.source);
		if (decoSprite.width != object.width || decoSprite.height != object.height)
		{
			decoSprite.antialiasing = true;
			decoSprite.setGraphicSize(object.width, object.height);
		}
		if (object.flippedHorizontally)
		{
			decoSprite.flipX = true;
		}
		if (object.flippedVertically)
		{
			decoSprite.flipY = true;
		}
		decoSprite.setPosition(object.x, object.y - decoSprite.height);
		decoSprite.origin.set(0, decoSprite.height);
		if (object.angle != 0)
		{
			decoSprite.angle = object.angle;
			decoSprite.antialiasing = true;
		}

		// Custom Properties
		if (object.properties.contains("depth"))
		{
			var depth = Std.parseFloat(object.properties.get("depth"));
			decoSprite.scrollFactor.set(depth, depth);
		}

		backgroundLayer.add(decoSprite);
	}

	function loadObject(o:TiledObject, g:TiledObjectLayer, group:FlxGroup)
	{
		var x:Int = o.x;
		var y:Int = o.y;

		// objects in tiled are aligned bottom-left (top-left in flixel)
		if (o.gid != -1)
			y -= g.map.getGidOwner(o.gid).tileHeight;

		switch (o.type.toLowerCase())
		{
			case 'player':
				START_POS = flixel.math.FlxPoint.get(o.x, o.y);
			case 'monster':
				var monster:Monster = new Monster(this);
				monster.setPosition(o.x, o.y);
				state.monsters.add(monster);
				if (!Settings.hideHealthbars)
				{
					state.HUDGroup.add(monster.healthbar);
				}
				if (!Settings.hideHUD)
				{
					for (value in monster.HUDMap)
						state.HUDGroup.add(value);
				}
			case 'wolf':
				var wolf:Wolf = new Wolf(this);
				wolf.setPosition(o.x, o.y);
				state.monsters.add(wolf);
				if (!Settings.hideHealthbars)
				{
					state.HUDGroup.add(wolf.healthbar);
				}
				if (!Settings.hideHUD)
				{
					for (value in wolf.HUDMap)
						state.HUDGroup.add(value);
				}
			case 'exit':
				state.exits.push(new FlxObject(o.x, o.y, o.width, o.height));
				state.exits[state.exits.length - 1].ID = state.exits.length - 1;
				state.add(state.exits[state.exits.length - 1]);
			case 'chest':
				var chest = new Interactable();
				state.interactables.push(chest);
				chest.mainObject.setPosition(o.x, o.y);
				chest.init_objects();
				chest.onInteract = () ->
				{
					for (i in 0...FlxG.random.int(4, 8))
					{
						var loot:Collectable = new Collectable();
						loot.setPosition(chest.mainObject.x, chest.mainObject.y);
						loot.velocity.set(FlxG.random.int(-500, 500), -500);
						state.collectables.add(loot);
						chest.chestLootSFX.play();
					}
				}
			case 'collidable':
				if (o.properties.get("angle") != null)
				{
					final sprite = new Slope(o.x, o.y, o.width, o.height, Std.parseInt(o.properties.get("angle")));

					final array_vertices = o.points;
					sprite.add_body({
						mass: 0,
						shape: {
							type: POLYGON,
							vertices: Misc.convertToEcho(array_vertices)
						}
					});
					collidableObjects.push(sprite);
				}
				else
				{
					final sprite = new FlxSprite(o.x, o.y).makeGraphic(o.width, o.height, FlxColor.TRANSPARENT);
					final array_vertices = o.points;
					sprite.add_body({
						mass: 0,
						shape: {
							type: POLYGON,
							vertices: Misc.convertToEcho(array_vertices)
						}
					});
					collidableObjects.push(sprite);
				}
		}
	}

	public function loadImages()
	{
		for (layer in layers)
		{
			if (layer.type != TiledLayerType.IMAGE)
				continue;

			var image:TiledImageLayer = cast layer;
			var sprite = new FlxSprite(image.x, image.y, c_PATH_LEVEL_TILESHEETS + image.imagePath);
			imagesLayer.add(sprite);
		}
	}

	function separateXYGeneric(spr:FlxSprite, obj:FlxSprite)
	{
		final daShape:Polygon = cast spr.get_body().shape;
		final lines = [
			Line.get(obj.x + obj.width, obj.y, obj.x + obj.width, obj.y + obj.height), // right
			Line.get(obj.x, obj.y, obj.x, obj.y + obj.height), // left
			Line.get(obj.x, obj.y, obj.x + obj.width, obj.y), // top
			Line.get(obj.x, obj.y + obj.height, obj.x + obj.width, obj.y + obj.height) // bottom
		];
		final intersections:Array<Bool> = [false, false, false, false];
		final edgePoints = [];
		for (i in 0...lines.length)
		{
			final line = lines[i];
			for (x in 0...daShape.vertices.length)
			{
				final vertex = daShape.vertices[x];
				final vertex2 = daShape.vertices[(x + 1 >= daShape.vertices.length ? 0 : x + 1)];
				final intersection = SAT.line_intersects_line(line, Line.get(vertex.x, vertex.y, vertex2.x, vertex2.y));
				if (intersection != null)
				{
					if (edgePoints[0] == null || intersection.hit.x > edgePoints[0])
						edgePoints[0] = intersection.hit.x;
					if (edgePoints[1] == null || intersection.hit.x < edgePoints[1])
						edgePoints[1] = intersection.hit.x;
					if (edgePoints[2] == null || intersection.hit.y > edgePoints[2])
						edgePoints[2] = intersection.hit.y;
					if (edgePoints[3] == null || intersection.hit.y < edgePoints[3])
						edgePoints[3] = intersection.hit.y;
					intersection.put();
					intersections[i] = true;
				}
				if (obj.getHitbox().containsPoint(FlxPoint.weak(vertex.x, vertex.y)))
				{
					if (edgePoints[0] == null || vertex.x > edgePoints[0])
						edgePoints[0] = vertex.x;
					if (edgePoints[1] == null || vertex.x < edgePoints[1])
						edgePoints[1] = vertex.x;
					if (edgePoints[2] == null || vertex.y > edgePoints[2])
						edgePoints[2] = vertex.y;
					if (edgePoints[3] == null || vertex.y < edgePoints[3])
						edgePoints[3] = vertex.y;
				}
			}
			line.put();
		}

		var newX:Float = obj.x;
		var newY:Float = obj.y;
		if (obj.velocity.x != 0)
		{
			if (!(intersections[1] && intersections[0]) && !(intersections[3]))
			{
				if (intersections[0])
				{
					obj.touching |= RIGHT;
					newX = edgePoints[1] - obj.width;
					if (!intersections[3])
						obj.velocity.x = 0;
				}
				if (intersections[1])
				{
					obj.touching |= LEFT;

					newX = edgePoints[0];
					if (!intersections[3])
						obj.velocity.x = 0;
				}
			}
		}
		if (obj.velocity.y != 0)
		{
			if (intersections[1] && intersections[0])
			{
				if (daShape.overlaps(Rect.get(obj.x, obj.y, 1, 1)))
				{
					obj.touching |= CEILING;
					newY = edgePoints[2];
					if (obj.velocity.y < 0)
						obj.velocity.y = 0;
				}
				else
				{
					obj.touching |= FLOOR;
					newY = edgePoints[3] - obj.height;
					obj.velocity.y = 0;
				}
			}
			else
			{
				if (intersections[3])
				{
					obj.touching |= FLOOR;
					newY = edgePoints[3] - obj.height;

					obj.velocity.y = 0;
				}
				if (intersections[2])
				{
					obj.touching |= CEILING;
					newY = edgePoints[2];

					if (obj.velocity.y < 0)
						obj.velocity.y = 0;
				}
			}
		}
		obj.x = newX;
		obj.y = newY;
	}

	function collidableCollisions(obj:FlxSprite):Bool
	{
		var collided:Bool = false;
		for (spr in collidableObjects)
		{
			@:privateAccess {
				if (obj != null && spr != null)
				{
					final ab = spr.get_body().bounds();
					final bb = obj.get_body().bounds();
					if (ab.overlaps(bb) && spr.get_body().shape.overlaps(obj.get_body().shape))
					{
						separateXYGeneric(spr, obj);
						collided = true;
					}
				}
			}
		}
		return collided;
	}

	public function collideWithLevel(obj:FlxBasic, ?notifyCallback:FlxObject->FlxObject->Void, ?processCallback:FlxObject->FlxObject->Bool):Bool
	{
		var collisionBool:Bool = false;
		if (collidableTileLayers == null)
			return collisionBool;
		if (collidableCollisions(cast obj))
			collisionBool = true;
		for (map in collidableTileLayers)
		{
			// IMPORTANT: Always collide the map with objects, not the other way around.
			//            This prevents odd collision errors (collision separation code off by 1 px).
			if (FlxG.overlap(map, obj, notifyCallback, processCallback != null ? processCallback : FlxObject.separate))
			{
				collisionBool = true;
				break;
			}
		}
		return collisionBool;
	}
}
