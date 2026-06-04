import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxCamera;
import funkin.backend.assets.Paths;
import haxe.Log;

var logText:FlxText;
var logHistory:Array<String> = [];
var maxLogLines:Int = 15;
var myLogCam:FlxCamera;

#if mobile
function postCreate() {
    myLogCam = new FlxCamera();
    myLogCam.bgColor = 0x00000000;
    FlxG.cameras.add(myLogCam, false);
  
    logText = new FlxText(10, 10, FlxG.width - 20, "", 16);
    logText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    logText.scrollFactor.set(0, 0); 
    logText.cameras = [myLogCam];
    
    FlxG.state.add(logText);

    if (FlxG.game.meta.get("traceHijacked") != true) {
        FlxG.game.meta.set("traceHijacked", true);
        
        var originalTrace = Log.trace;
        Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos) {
            originalTrace(v, infos);

            var msg:String = Std.string(v);
            logHistory.push(msg);
            
            if (logHistory.length > maxLogLines) {
                logHistory.shift();
            }
            
            if (logText != null) {
                logText.text = logHistory.join("\n");
            }
        };
    }
}
#end
