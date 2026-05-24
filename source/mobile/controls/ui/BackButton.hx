package mobile.controls.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouse;
import funkin.backend.assets.Paths;

class BackButton extends FlxSprite {

	public static var isPressingBack:Bool = false;
	public static var buttonCam:FlxCamera;

	public function new(x:Float = 1000, y:Float = 475) {
		super(x, y);

		if (buttonCam == null) {
			buttonCam = new FlxCamera();
			buttonCam.bgColor.alpha = 0;
			FlxG.cameras.add(buttonCam, false);
		}

		cameras = [buttonCam];
		frames = Paths.getSparrowAtlas('backButton');

		animation.addByPrefix('idle', 'back0000', 24, true);
		animation.addByPrefix('clicked', 'back pressed', 24, false);

		animation.play('idle');
		scale.set(0.85, 0.85);
		updateHitbox();
		scrollFactor.set(0, 0);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		var hovering:Bool = false;
		var pointerJustPressed:Bool = false;
		var pointerJustReleased:Bool = false;

		if (FlxG.mouse.overlaps(this, cameras[0])) {
			hovering = true;
			if (FlxG.mouse.justPressed) pointerJustPressed = true;
		}
		
		if (FlxG.mouse.justReleased) pointerJustReleased = true;

		for (touch in FlxG.touches.list) {
			if (touch.overlaps(this, cameras[0])) {
				hovering = true;
				if (touch.justPressed) pointerJustPressed = true;
			}
			if (touch.justReleased) pointerJustReleased = true;
		}

		FlxMouse.globallyBlocked = hovering;

		if (hovering && pointerJustPressed) {
			isPressingBack = true;
			animation.play('clicked', true);
			FlxG.keys.handleAction(FlxKey.BACKSPACE, true);
		}

		if (isPressingBack && pointerJustReleased) {
			isPressingBack = false;
			animation.play('idle');
			FlxG.keys.handleAction(FlxKey.BACKSPACE, false);
		}
	}
}
