package funkin.backend.scripting;

import hscript.*;
import hscript.Expr.Error;
import hscript.Parser;
import openfl.Assets;
#if mobile
import mobile.ui.menus.FunkinPad;
import funkin.backend.utils.NativeAPI;
import flixel.input.keyboard.FlxKey;
import flixel.ui.FlxButton;
import mobile.backend.utils.MobileTrace;
#end
#if android
import extension.androidtools.Tools;
#end

class HScript extends Script {
	public var interp:Interp;
	public var parser:Parser;
	public var expr:Expr;
	public var code:String = null;

	public static var currentScript:String = "";
    public static var currentFunction:String = "";
    public static var callLog:Array<String> = [];
	//public var folderlessPath:String;
	var __importedPaths:Array<String>;

	public static function initParser() {
		var parser = new Parser();
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
		parser.preprocessorValues = Script.getDefaultPreprocessors();
		return parser;
	}

	public override function onCreate(path:String) {
		super.onCreate(path);

		interp = new Interp();

		try {
			if(Assets.exists(rawPath)) code = Assets.getText(rawPath);
		} catch(e) Logs.error('Error while reading $path: ${Std.string(e)}');

		parser = initParser();
		//folderlessPath = Path.directory(path);
		__importedPaths = [path];

		interp.errorHandler = _errorHandler;
		interp.warnHandler = _warnHandler;
		interp.importFailedCallback = importFailedCallback;
		interp.staticVariables = Script.staticVariables;
		interp.allowStaticVariables = interp.allowPublicVariables = true;
		#if mobile
		interp.variables.set("VirtualPad", mobile.ui.menus.FunkinPad);

        interp.variables.set("addVirtualPad", function(dpadModeStr:String, actionModeStr:String) {
            var dpadMode = Type.createEnum(mobile.ui.menus.FunkinPad.FlxDPadMode, dpadModeStr);
            var actionMode = Type.createEnum(mobile.ui.menus.FunkinPad.FlxActionMode, actionModeStr);
    
            var vpad = new mobile.ui.menus.FunkinPad(dpadMode, actionMode);
            flixel.FlxG.state.add(vpad); 
            interp.variables.set("virtualPad", vpad);
    
            return vpad;
        });
		#end

		interp.variables.set("addCustomButton", function(x:Float, y:Float, assetPath:String, keyStr:String, animName:String = "", playOnlyWhenPressed:Dynamic = "true", size:Dynamic = 1.0) {
             var btn:Dynamic = null;
             try {
                btn = new mobile.controls.MobileButton(x, y);
                } catch(e:Dynamic) {
                btn = new flixel.FlxSprite(x, y);
            }
    
            var hasXML = false;
            var onlyOnPress:Bool = (Std.string(playOnlyWhenPressed).toLowerCase() != "false");

            try {
                var atlas = Paths.getSparrowAtlas(assetPath);
                if (atlas != null && atlas.frames != null) {
                    btn.frames = atlas;
                    hasXML = true;

                    if (animName != "") {
                        btn.animation.addByPrefix(animName, animName, 24, !onlyOnPress);
                        if (btn.animation.getByName("normal") == null) btn.animation.addByPrefix("normal", "normal", 24, false);
                        btn.animation.play(onlyOnPress ? "normal" : animName);
                    } else {
                        btn.animation.addByPrefix("normal", "normal", 24, false);
                        btn.animation.addByPrefix("pressed", "pressed", 24, false);

                        if (btn.animation.getByName("normal") == null) btn.animation.addByPrefix("normal", assetPath + " normal", 24, false);
                        if (btn.animation.getByName("pressed") == null) btn.animation.addByPrefix("pressed", assetPath + " pressed", 24, false);
                        btn.animation.play("normal");
                    }
                }
            } catch(e:Dynamic) {}

            if (!hasXML) {
                try {
                var graphic = Paths.image(assetPath);
                if (graphic != null) {
                    btn.loadGraphic(graphic);
                    } else {
                         return null;
                    }
                  } catch(e:Dynamic) {
                 return null;
                }
            }

            var scaleAmt:Float = Std.parseFloat(Std.string(size));
            if (Math.isNaN(scaleAmt)) scaleAmt = 1.0;
            btn.scale.set(scaleAmt, scaleAmt);
            btn.updateHitbox();
            btn.scrollFactor.set();

			var vpCam:Dynamic = interp.variables.get("touchCam");
			var vpad:Dynamic = interp.variables.get("virtualPad");
			
			if (vpCam == null) {
                vpCam = new flixel.FlxCamera();
                vpCam.bgColor = 0x00000000;
                flixel.FlxG.cameras.add(vpCam, false);
        
                interp.variables.set("touchCam", vpCam);
			}

			try { btn.camera = vpCam; } catch(e:Dynamic) {}
            try { btn.cameras = [vpCam]; } catch(e:Dynamic) {}
    
            if (vpad != null && vpad.exists) {
                vpad.add(btn);
            } else {
                flixel.FlxG.state.add(btn);
	        }

            var key = flixel.input.keyboard.FlxKey.fromString(keyStr.toUpperCase());
            var wasPressed = false;

            var updateHook:Void->Void = null;
              updateHook = function() {
                try {
                    if (btn == null || !btn.exists || !btn.visible) {
                        flixel.FlxG.signals.preUpdate.remove(updateHook);
                        return;
                    } 
					
                    var isPressed = false;

					if (flixel.FlxG.mouse.pressed && flixel.FlxG.mouse.overlaps(btn, vpCam)) {
                        isPressed = true;
                    }

                    try {
                        if (mobile.ui.menus.FunkinPad.lastUpdateFrame != flixel.FlxG.game.ticks) {
                            mobile.ui.menus.FunkinPad.usedTouches = [];
                            mobile.ui.menus.FunkinPad.lastUpdateFrame = flixel.FlxG.game.ticks;
                        }
                    } catch(e:Dynamic) {}

                    for (touch in flixel.FlxG.touches.list) {
                        if (touch.pressed) {
                            var isUsed = false;
                            try {
                                if (mobile.ui.menus.FunkinPad.usedTouches.contains(touch)) isUsed = true;
                            } catch(e:Dynamic) {}

                            if (!isUsed) {
                                var touchPos = touch.getWorldPosition(vpCam);
                                if (btn.overlapsPoint(touchPos, true, vpCam)) {
                                    isPressed = true;
                                    try {
                                       mobile.ui.menus.FunkinPad.usedTouches.push(touch);
                                       } catch(e:Dynamic) {}
                                       touchPos.put(); 
                                           break;
                                           }
						    touchPos.put();							
                            }
                        }
                    }

                    try {
                        btn.justPressed = isPressed && !wasPressed;
                        btn.justReleased = !isPressed && wasPressed;
                        btn.pressed = isPressed;
                    } catch(e:Dynamic) {}
 
                    if (hasXML) {
                        if (animName != "") {
                            if (onlyOnPress) {
                                if (isPressed) btn.animation.play(animName, false);
                                else if (btn.animation.getByName("normal") != null) btn.animation.play("normal");
                                else if (btn.animation.curAnim != null) btn.animation.curAnim.curFrame = 0;
                            }
                        } else {
                            if (isPressed) btn.animation.play("pressed");
                            else btn.animation.play("normal");
                        }
                    }

                    if (key != flixel.input.keyboard.FlxKey.NONE) {
                        var justPressed = isPressed && !wasPressed;
                        var justReleased = !isPressed && wasPressed;

                        @:privateAccess {
                            if (justPressed) flixel.FlxG.keys._keyListMap[key].current = JUST_PRESSED;
                            else if (justReleased) flixel.FlxG.keys._keyListMap[key].current = JUST_RELEASED;
                            else if (isPressed && flixel.FlxG.keys._keyListMap[key].current == JUST_PRESSED) flixel.FlxG.keys._keyListMap[key].current = PRESSED;
                            else if (!isPressed && flixel.FlxG.keys._keyListMap[key].current == JUST_RELEASED) flixel.FlxG.keys._keyListMap[key].current = RELEASED;
                        } 
                    }

                    wasPressed = isPressed;

                } catch(e:Dynamic) {
                    flixel.FlxG.signals.preUpdate.remove(updateHook);
                }
            };

            flixel.FlxG.signals.preUpdate.add(updateHook);
            return btn;
        });
		
		interp.variables.set("trace", Reflect.makeVarArgs((args) -> {
			var v:String = Std.string(args.shift());
			for (a in args) v += ", "+ Std.string(a);
			this.trace(v);
			#if mobile
			MobileTrace.log(v);
			#end
		}));

		#if GLOBAL_SCRIPT
		funkin.backend.scripting.GlobalScript.call("onScriptCreated", [this, "hscript"]);
		#end
		loadFromString(code);
	}

	public override function loadFromString(code:String) {
		try {
			if (code != null && code.trim() != "")
				expr = parser.parseString(code, fileName);
		} catch(e:Error) {
			_errorHandler(e);
		} catch(e) {
			_errorHandler(new Error(ECustom(e.toString()), 0, 0, fileName, 0));
		}

		return this;
	}

	private function importFailedCallback(cl:Array<String>, ?asName:String):Bool {
		if(_importFailedCallback(cl, "source/") || _importFailedCallback(cl, "")) {
			return true;
		}
		return false;
	}
	private function _importFailedCallback(cl:Array<String>, prefix:String):Bool {
		var assetsPath = 'assets/$prefix${cl.join("/")}';
		for(hxExt in ["hx", "hscript", "hsc", "hxs"]) {
			var p = '$assetsPath.$hxExt';
			if (__importedPaths.contains(p))
				return true; // no need to reimport again
			if (Assets.exists(p)) {
				var code = Assets.getText(p);
				var expr:Expr = null;
				try {
					if (code != null && code.trim() != "") {
						parser.line = 1; // fun fact: this is all you need to reuse a parser without issues. all the other vars get reset on parse.
						expr = parser.parseString(code, cl.join("/") + "." + hxExt);
					}
				} catch(e:Error) {
					_errorHandler(e);
				} catch(e) {
					_errorHandler(new Error(ECustom(e.toString()), 0, 0, fileName, 0));
				}
				if (expr != null) {
					@:privateAccess
					interp.exprReturn(expr);
					__importedPaths.push(p);
				}
				return true;
			}
		}
		return false;
	}

	private function _errorHandler(error:Error) {
		var fileName = error.origin;
		var oldfn = '$fileName:${error.line}: ';
		if(remappedNames.exists(fileName))
			fileName = remappedNames.get(fileName);
		var fn = '$fileName:${error.line}: ';
		var err = error.toString();
		while(err.startsWith(oldfn) || err.startsWith(fn)) {
			if (err.startsWith(oldfn)) err = err.substr(oldfn.length);
			if (err.startsWith(fn)) err = err.substr(fn.length);
		}

		Logs.traceColored([
			Logs.logText(fn, GREEN),
			Logs.logText(err, RED)
		], ERROR);

		#if mobile
	    NativeAPI.showMessageBox("HScript Error!", fn + "\n" + Std.string(err), "Got It!");
	    #end
	}

	private function _warnHandler(error:Error) {
		var fileName = error.origin;
		var oldfn = '$fileName:${error.line}: ';
		if(remappedNames.exists(fileName))
			fileName = remappedNames.get(fileName);
		var fn = '$fileName:${error.line}: ';
		var err = error.toString();
		while(err.startsWith(oldfn) || err.startsWith(fn)) {
			if (err.startsWith(oldfn)) err = err.substr(oldfn.length);
			if (err.startsWith(fn)) err = err.substr(fn.length);
		}

		Logs.traceColored([
			Logs.logText(fn, GREEN),
			Logs.logText(err, YELLOW)
		], WARNING);

		#if android
    	NativeAPI.showMessageBox("HScript Warning!", fn + "\n" + Std.string(err), "Got It!");
    	#end
	}

	public override function setParent(parent:Dynamic) {
		interp.scriptObject = parent;
	}

	public override function onLoad() {
		@:privateAccess
		interp.execute(parser.mk(EBlock([]), 0, 0));
		if (expr != null) {
			interp.execute(expr);
			call("new", []);
		}

		#if GLOBAL_SCRIPT
		funkin.backend.scripting.GlobalScript.call("onScriptSetup", [this, "hscript"]);
		#end
	}

	public override function reload() {
		// save variables

		interp.allowStaticVariables = interp.allowPublicVariables = false;
		var savedVariables:Map<String, Dynamic> = [];
		for(k=>e in interp.variables) {
			if (!Reflect.isFunction(e)) {
				savedVariables[k] = e;
			}
		}
		var oldParent = interp.scriptObject;
		onCreate(path);

		for(k=>e in Script.getDefaultVariables(this))
			set(k, e);

		load();
		setParent(oldParent);

		for(k=>e in savedVariables)
			interp.variables.set(k, e);

		interp.allowStaticVariables = interp.allowPublicVariables = true;
	}

	private override function onCall(funcName:String, parameters:Array<Dynamic>):Dynamic {
        if (interp == null) return null;
        if (!interp.variables.exists(funcName)) return null;

        currentScript = fileName;
        currentFunction = funcName;

        callLog.push(fileName + " -> " + funcName);

        while (callLog.length > 25)
            callLog.shift();

        var func = interp.variables.get(funcName);

        if (func != null && Reflect.isFunction(func)) {
            var result = Reflect.callMethod(null, func, parameters);
            return result;
        }
        return null;
	}
	public override function get(val:String):Dynamic {
		return interp.variables.get(val);
	}

	public override function set(val:String, value:Dynamic) {
		interp.variables.set(val, value);
	}

	public override function trace(v:Dynamic) {
		var posInfo = interp.posInfos();
		Logs.traceColored([
			Logs.logText('${fileName}:${posInfo.lineNumber}: ', GREEN),
			Logs.logText(Std.isOfType(v, String) ? v : Std.string(v))
		], TRACE);
	}

	public override function setPublicMap(map:Map<String, Dynamic>) {
		this.interp.publicVariables = map;
	}
}
