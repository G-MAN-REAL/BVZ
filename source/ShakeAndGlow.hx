package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxRandom;
import flixel.system.FlxAssets;
import lime.math.Vector2;

class ShakeAndGlow extends FlxSprite
{
	public var _shader:ShakeAndGlowShader = new ShakeAndGlowShader();

	var maxBorder:Int = 0;
	var bind:FlxSprite;

	public function new(borderSize:Float = 0, bind:FlxSprite)
	{
		super();
		_shader.u_time.value = [0];
		_shader.borderSize.value = [0];
		this.bind = bind;
		this.pixels = bind.updateFramePixels();
		shader = _shader;
		_shader.triggered.value = [false];
	}

	override public function update(elapsed:Float)
	{
		setPosition(bind.x, bind.y);
		bind.offset.copyTo(offset);
		scale = bind.scale;
		_shader.offset.value = [FlxG.random.int(1, 4), FlxG.random.int(1, 4)];
		_shader.u_time.value[0] += elapsed;
		_shader.borderSize.value[0]++;
		this.pixels = bind.updateFramePixels();
		super.update(elapsed);
	}
}

class ShakeAndGlowShader extends FlxShader
{
	@:glFragmentSource('
    #pragma header

    uniform vec2 offset;
    uniform float u_time;
    uniform float borderSize;
    uniform bool triggered;

    void main()
    {
        vec4 sample = flixel_texture2D(bitmap, openfl_TextureCoordv);
        if (triggered){
        vec2 scaledOffset = offset / openfl_TextureSize;
        vec2 scaledBorder = abs(sin(u_time * 2)) / 25.0;
        sample = flixel_texture2D(bitmap, openfl_TextureCoordv + scaledOffset);
        if (sample.a != 0.0)
            sample.rgb += abs(sin(u_time * 2)) / 2.0;
        else
        {
			vec2 arr[8];
			arr[0].x = arr[1].x = arr[2].x = arr[0].y = arr[3].y = arr[5].y = 1.0;
			arr[3].x = arr[4].x = arr[1].y = arr[6].y = 0.0;
			arr[5].x = arr[6].x = arr[7].x = arr[2].y = arr[4].y = arr[7].y = -1.0;
			for (int i = 0; i < 8; i++)
			{
				if (flixel_texture2D(bitmap, openfl_TextureCoordv + scaledOffset + arr[i] * scaledBorder).a != 0.0)
                    sample.rgba += 0.1;
			}
        }}
        gl_FragColor = sample;
    }
    
    
    
    ')
	public function new()
	{
		super();
	}
}
