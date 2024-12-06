package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class TitleState extends RhythmState
{
	var bg:FlxSprite;
	var pressText:FlxText;
	final dialogue:Array<String> = [
		"FROM THE CREATIVE MIND OF",
		"GOODBOYAUDIOS",
		"THE ARTISTIC TALENT OF",
		"INTERESTED BEE",
		"THE PROGRAMMING OF",
		"G-MAN",
		"WE BRING YOU"
	];
	var textGroup:Array<FlxText> = [];
	var completedIntro:Bool = false;
	var letters:FlxTypedGroup<FlxText>;
	var zoomTween:FlxTween;

	override public function create()
	{
		Settings.loadSettings();
		Misc.initKeyMap();
		BPM = 130;
		FlxG.sound.playMusic(AssetPaths.swous__ogg);
		bg = new FlxSprite().loadGraphic(AssetPaths.bg__png);
		add(bg);
		bg.scale.set(1.2, 1.2);
		bg.updateHitbox();
		letters = new FlxTypedGroup<FlxText>();
		add(letters);

		var bvz:String = "BASTARDS VERSUS ZOMBIES";
		var lastX:Float = 0;
		for (character in 0...bvz.length)
		{
			var text = new FlxText(-FlxG.width + lastX, FlxG.height / 2 - 400, bvz.charAt(character), 110);
			text.font = AssetPaths.Crang__ttf;
			text.ID = character;
			lastX += text.width;
			letters.add(text);
		}
		pressText = new FlxText(FlxG.width + 500, FlxG.height / 2, 0, "PRESS ENTER TO CONTINUE", 72);
		pressText.font = AssetPaths.chunkypixel__TTF;
		add(pressText);
		super.create();
	}

	override public function update(elapsed)
	{
		if (FlxG.keys.justPressed.ENTER)
		{
			if (!completedIntro)
				textNum = dialogue.length + 1;
			else if (zoomTween == null)
				zoomTween = FlxTween.tween(camera, {alpha: 0}, 0.5, {
					onComplete: function(twn:FlxTween)
					{
						FlxG.switchState(new MainMenuState());
					}
				});
		}
		pressText.scale.x = Math.sin(time * 3) / 10 + 1.1;
		for (letter in letters)
			letter.y = Math.sin(time * 4 + letter.ID) * 10 + FlxG.height / 2 - 400;
		super.update(elapsed);
	}

	var textNum:Int = 0;

	function addText(string:String, firstText:Bool = false)
	{
		var fooText:FlxText = new FlxText(0, 0, 0, string, 72);
		fooText.font = AssetPaths.chunkypixel__TTF;
		fooText.screenCenter();
		if (firstText)
			fooText.y -= 100;
		add(fooText);
		textGroup.push(fooText);
		textNum++;
	}

	function destroyText()
	{
		for (text in textGroup)
		{
			text.destroy();
		}
	}

	override function beatHit()
	{
		super.beatHit();
		trace(curBeat);
		if (textNum < dialogue.length + 1 && !completedIntro)
		{
			switch (curBeat % 8)
			{
				case 0:
					addText(dialogue[textNum], true);
				case 3:
					addText(dialogue[textNum], false);
				case 6:
					destroyText();
			}
		}
		else if (!completedIntro)
		{
			destroyText();
			completedIntro = true;
			FlxG.camera.flash();
			var width = letters.members[letters.members.length - 1].x - letters.members[0].x + letters.members[letters.members.length - 1].width;
			for (letter in letters)
			{
				FlxTween.tween(letter, {x: letter.x + FlxG.width + (FlxG.width - width) / 2}, 0.4, {ease: FlxEase.backInOut});
			}
			FlxTween.tween(pressText, {x: (FlxG.width - pressText.width) / 2}, 0.4, {ease: FlxEase.backInOut});
		}
	}
}
