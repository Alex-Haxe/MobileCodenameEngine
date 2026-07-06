package funkin.menus;

#if MOD_SUPPORT
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.backend.assets.ModsFolder;
import haxe.io.Path;
import sys.FileSystem;
#if mobile
import mobile.ui.menus.FunkinPad;
import mobile.ui.FunkinButton;
#end

class ModSwitchMenu extends MusicBeatSubstate {
	var mods:Array<String> = [];
	var alphabets:FlxTypedGroup<Alphabet>;
	var curSelected:Int = 0;

	var subCam:FlxCamera;

	var touchY:Float = 0;
	var touchSwiped:Bool = false;

	public override function create() {
		super.create();

		camera = subCam = new FlxCamera();
		subCam.bgColor = 0;
		FlxG.cameras.add(subCam, false);

		var bg = new FlxSprite(0, 0).makeSolid(FlxG.width, FlxG.height, 0xFF000000);
		bg.updateHitbox();
		bg.scrollFactor.set();
		add(bg);

		bg.alpha = 0;
		FlxTween.tween(bg, {alpha: 0.5}, 0.25, {ease: FlxEase.cubeOut});

		mods = ModsFolder.getModsList();
		mods.push(null);

		alphabets = new FlxTypedGroup<Alphabet>();
		for(mod in mods) {
			var a = new Alphabet(0, 0, mod == null ? TU.translate("mods.disableMods") : Path.withoutExtension(mod), "bold");
			if(mod == ModsFolder.currentModFolder)
				a.color = FlxColor.LIME;
			a.isMenuItem = true;
			a.scrollFactor.set();
			alphabets.add(a);
		}
		add(alphabets);
		changeSelection(0, true);

		#if mobile
		if (Options.useVirtualPad) {
	        virtualPad = new FunkinPad(UP_DOWN, A_B);
            add(virtualPad);
		} else {
			// nothing
		}
		#end
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		changeSelection((controls.DOWN_P ? 1 : 0) + (controls.UP_P ? -1 : 0) - FlxG.mouse.wheel);

		if (!Options.useVirtualPad) {
			for (touch in FlxG.touches.list) {
				if (touch.justPressed) {
					touchY = touch.y;
					touchSwiped = false;
				}

				if (touch.pressed) {
					if (Math.abs(touch.y - touchY) > 25) {
						changeSelection(touch.y > touchY ? -1 : 1);
						touchY = touch.y;
						touchSwiped = true;
					}
				}

				if (touch.justReleased && !touchSwiped) {
					for (item in alphabets) {
						if (touch.overlaps(item, subCam)) {
							if (curSelected != alphabets.members.indexOf(item)) {
								curSelected = alphabets.members.indexOf(item);
								changeSelection(0, true);
							} else {
								ModsFolder.switchMod(mods[curSelected]);
								close();
							}
						}
					}
				}
			}
		}

		if (controls.ACCEPT) {
			ModsFolder.switchMod(mods[curSelected]);
			close();
		}

		if (controls.BACK)
			close();
	}

	public function changeSelection(change:Int, force:Bool = false) {
		if (change == 0 && !force) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, alphabets.length-1);

		CoolUtil.playMenuSFX(SCROLL, 0.7);

		for(k=>alphabet in alphabets.members) {
			alphabet.alpha = 0.6;
			alphabet.targetY = k - curSelected;
		}
		alphabets.members[curSelected].alpha = 1;
	}

	override function destroy() {
		super.destroy();

		if (FlxG.cameras.list.contains(subCam))
			FlxG.cameras.remove(subCam);
	}
}
#end
