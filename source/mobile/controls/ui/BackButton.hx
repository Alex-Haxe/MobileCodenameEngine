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
		animation.addByPrefix('clicked', 'back', 24, false);

		animation.play('idle');

		scale.set(0.85, 0.85);

		updateHitbox();

		scrollFactor.set(0, 0);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		var hovering:Bool = FlxG.mouse.overlaps(this, cameras[0]);

		FlxMouse.globallyBlocked = hovering;

		if (hovering && FlxG.mouse.justPressed) {
			isPressingBack = true;

			animation.play('clicked', true);

			FlxG.keys.handleAction(FlxKey.BACKSPACE, true);
		}

		if (isPressingBack && FlxG.mouse.justReleased) {
			isPressingBack = false;

			animation.play('idle');

			FlxG.keys.handleAction(FlxKey.BACKSPACE, false);
		}

		if (animation.curAnim != null
			&& animation.curAnim.name == 'clicked'
			&& animation.curAnim.finished) {
			animation.play('idle');
		}
	}
}
