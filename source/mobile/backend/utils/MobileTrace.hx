package mobile.backend.utils;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class MobileTrace
{
	public static var text:FlxText;

	public static var enabled:Bool = false;

	public static function init()
    {
        if (text != null)
            return;

        if (FlxG.state == null)
            return;

        text = new FlxText(10, 10, FlxG.width - 20, "");
        text.setFormat(null, 16, FlxColor.GREEN);
        text.scrollFactor.set();
        text.alpha = 0.7;
        text.borderSize = 1;

        if (FlxG.cameras.list.length > 0)
            text.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        FlxG.state.add(text);
    }
	
	public static function log(msg:Dynamic, ?color:FlxColor)
	{
		if (!enabled) return;
		
		if (text == null) return;

		if (color != null)
			text.color = color;

		text.text += Std.string(msg) + "\n";

		var lines = text.text.split("\n");
		if (lines.length > 15)
			lines.shift();

		text.text = lines.join("\n");
	}
}
