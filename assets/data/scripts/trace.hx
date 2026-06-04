import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxCamera;

var logText:FlxText;
var logHistory:Array<String> = [];
var maxLogLines:Int = 15;

#if mobile
function postCreate() {
    camOther = new FlxCamera();
    camOther.bgColor = 0x00000000;
    FlxG.cameras.add(camOther, false);
  
    logText = new FlxText(10, 10, FlxG.width - 20, "", 16);
    
    logText.setFormat(null, 16, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    logText.scrollFactor.set(0, 0); 
    
    logText.cameras = [camOther];
    
    add(logText);
}

function logScreen(text:Dynamic) {
    var msg:String = Std.string(text);
    
    trace(msg);
    
    logHistory.push(msg);
    
    if (logHistory.length > maxLogLines) {
        logHistory.shift();
    }
    
    if (logText != null) {
        logText.text = logHistory.join("\n");
    }
}
#end
