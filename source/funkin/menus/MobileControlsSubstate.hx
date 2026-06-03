package funkin.menus;

#if mobile
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import mobile.controls.VirtualPad;
import mobile.controls.HitBox;
import funkin.backend.assets.Paths;
import funkin.options.Options;
import funkin.backend.MusicBeatSubstate;
import funkin.menus.ui.Alphabet;

class MobileControlsSubstate extends MusicBeatSubstate
{
	var options:Array<String> = ['Hitbox', 'Dpad', 'Double Dpad', 'Custom', 'None'];
	var curSelected:Int = 0;

	var modeText:Alphabet;
	var subCam:FlxCamera;
	var bg:FlxSprite;

	var previewBox:HitBox;
	var previewPad:VirtualPad;
	var previewDoublePad:VirtualPad;
	var customPad:VirtualPad;
	var menuButtons:VirtualPad;

	var isCustomizing:Bool = false;
	var acceptBlocked:Bool = true;

	var bindButton:FlxSprite;

	var hiddenPads:Array<VirtualPad> = [];

	public function new()
	{
		super();
		this.persistentUpdate = false;
	}

	private function setupPadCamera(pad:VirtualPad):Void
	{
		if (pad == null) return;

		if (pad.virtualpadCamera != null && FlxG.cameras.list.contains(pad.virtualpadCamera))
		{
			FlxG.cameras.remove(pad.virtualpadCamera, true);
			pad.virtualpadCamera = null;
		}

		pad.cameras = [subCam];
		pad.forEachAlive(function(button:FlxSprite) {
			button.cameras = [subCam];
		});
	}

	function setPadEnabled(pad:VirtualPad, enabled:Bool, targetAlpha:Float = 1.0)
	{
		if (pad == null) return;

		pad.visible = enabled;
		pad.active = enabled;
		
		pad.forEachAlive(function(button:FlxSprite) {
			button.visible = enabled;
			button.active = enabled;
			button.alpha = targetAlpha;
		});
	}

	public override function create()
	{
		super.create();

		persistentUpdate = false;

		FlxG.mouse.reset();
		FlxG.touches.reset();

		if (VirtualPad.activePads != null) {
			for (pad in VirtualPad.activePads.copy())
			{
				if (pad == null) continue;
				pad.visible = false;
				pad.active = false;
				pad.blockInput = true;
				hiddenPads.push(pad);
			}
		}

		camera = subCam = new FlxCamera();
		subCam.bgColor = 0;
		FlxG.cameras.add(subCam, false);

		bg = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF000000);
		bg.scrollFactor.set();
		bg.alpha = 0;
		bg.blockInput = true;
		add(bg);

		FlxTween.tween(bg, {alpha: 0.85}, 0.25, {ease: FlxEase.cubeOut});

		var savedMode:String = Options.mobilecontrols;
		if (savedMode != null && options.contains(savedMode)) {
			curSelected = options.indexOf(savedMode);
		}

		modeText = new Alphabet(0, 40, "", true);
		modeText.isMenuItem = false;
		modeText.cameras = [subCam];
		add(modeText);

		previewBox = new HitBox(Options.hitboxStyle, Options.hintStyle);
		previewBox.setupCamera();
		previewBox.cameras = [subCam];
		previewBox.blockInput = true;
		previewBox.forEachAlive(function(btn:FlxSprite) {
			btn.cameras = [subCam];
		});
		previewBox.visible = false;
		previewBox.active = false;
		add(previewBox);

		previewPad = new VirtualPad(FULL, NONE);
		setupPadCamera(previewPad);
		previewPad.blockInput = true;
		add(previewPad);

		previewDoublePad = new VirtualPad(DOUBLE, NONE);
		setupPadCamera(previewDoublePad);
		previewDoublePad.blockInput = true;
		add(previewDoublePad);

		customPad = new VirtualPad(CUSTOM, NONE);
		setupPadCamera(customPad);
		customPad.blockInput = true;
		add(customPad);

		menuButtons = new VirtualPad(NONE, A_B);
		setupPadCamera(menuButtons);
		menuButtons.blockInput = false;
		add(menuButtons);

		setPadEnabled(previewPad, false);
		setPadEnabled(previewDoublePad, false);
		setPadEnabled(customPad, false);

		changeSelection(0, true);
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (acceptBlocked)
		{
			var stillPressed = controls.ACCEPT;
			if (menuButtons.buttonA != null) stillPressed = stillPressed || menuButtons.buttonA.pressed;
			if (!stillPressed) acceptBlocked = false;
			return;
		}

		if (!isCustomizing)
		{
			var leftPressed = false;
			var rightPressed = false;

			for (touch in FlxG.touches.list)
			{
				if (!touch.justPressed) continue;

				var pos = touch.getWorldPosition(subCam);
				if (pos.y < FlxG.height * 0.5)
				{
					if (pos.x < FlxG.width * 0.5) leftPressed = true;
					else rightPressed = true;
				}
				pos.put();
			}

			if (leftPressed || controls.LEFT_P) changeSelection(-1);
			else if (rightPressed || controls.RIGHT_P) changeSelection(1);

			if (controls.ACCEPT || (menuButtons.buttonA != null && menuButtons.buttonA.justPressed))
				acceptSelection();

			if (controls.BACK || (menuButtons.buttonB != null && menuButtons.buttonB.justPressed))
				close();
		}
		else
		{
			handleCustomDrag();

			if (menuButtons.buttonA != null && menuButtons.buttonA.justPressed)
			{
				saveCustomLayout();
				saveAndClose();
			}

			if (menuButtons.buttonB != null && menuButtons.buttonB.justPressed)
			{
				isCustomizing = false;
				bindButton = null;
				modeText.visible = true;
				customPad.blockInput = true;
				updatePreview();
			}
		}
	}

	function acceptSelection()
	{
		if (options[curSelected] == 'Custom') enterCustomization();
		else saveAndClose();
	}

	function enterCustomization()
	{
		isCustomizing = true;
		modeText.visible = false;
		previewBox.visible = false;

		setPadEnabled(previewPad, false);
		setPadEnabled(previewDoublePad, false);
		setPadEnabled(customPad, true, 1.0);

		customPad.blockInput = false;
		loadCustomLayout();
	}

	function handleCustomDrag()
	{
		var pointerPressed:Bool = false;
		var pointerJustPressed:Bool = false;
		var pointerX:Float = 0;
		var pointerY:Float = 0;

		#if mobile
		for (touch in FlxG.touches.list) {
			pointerPressed = touch.pressed;
			pointerJustPressed = touch.justPressed;
			pointerX = touch.getWorldPosition(subCam).x;
			pointerY = touch.getWorldPosition(subCam).y;
			break;
		}
		#else
		pointerPressed = FlxG.mouse.pressed;
		pointerJustPressed = FlxG.mouse.justPressed;
		pointerX = FlxG.mouse.getWorldPosition(subCam).x;
		pointerY = FlxG.mouse.getWorldPosition(subCam).y;
		#end

		if (bindButton != null)
		{
			if (pointerPressed)
			{
				bindButton.x = FlxMath.bound(pointerX - (bindButton.width / 2), 0, FlxG.width - bindButton.width);
				bindButton.y = FlxMath.bound(pointerY - (bindButton.height / 2), 0, FlxG.height - bindButton.height);
			}
			else
			{
				bindButton = null;
			}
		}
		else if (pointerJustPressed)
		{
			customPad.forEachAlive(function(btn:FlxSprite) {
				if (pointerX >= btn.x && pointerX <= btn.x + btn.width && 
					pointerY >= btn.y && pointerY <= btn.y + btn.height) 
				{
					bindButton = btn;
				}
			});
		}
	}

	function saveCustomLayout()
	{
		FlxG.save.data.customPadPos = {
			upX: customPad.buttonUp != null ? customPad.buttonUp.x : 0,
			upY: customPad.buttonUp != null ? customPad.buttonUp.y : 0,
			downX: customPad.buttonDown != null ? customPad.buttonDown.x : 0,
			downY: customPad.buttonDown != null ? customPad.buttonDown.y : 0,
			leftX: customPad.buttonLeft != null ? customPad.buttonLeft.x : 0,
			leftY: customPad.buttonLeft != null ? customPad.buttonLeft.y : 0,
			rightX: customPad.buttonRight != null ? customPad.buttonRight.x : 0,
			rightY: customPad.buttonRight != null ? customPad.buttonRight.y : 0,
		};
		FlxG.save.flush();
	}

	function loadCustomLayout()
	{
		var save = FlxG.save.data.customPadPos;
		if (save == null) return;

		if (save.upX != null && customPad.buttonUp != null) { customPad.buttonUp.x = save.upX; customPad.buttonUp.y = save.upY; }
		if (save.downX != null && customPad.buttonDown != null) { customPad.buttonDown.x = save.downX; customPad.buttonDown.y = save.downY; }
		if (save.leftX != null && customPad.buttonLeft != null) { customPad.buttonLeft.x = save.leftX; customPad.buttonLeft.y = save.leftY; }
		if (save.rightX != null && customPad.buttonRight != null) { customPad.buttonRight.x = save.rightX; customPad.buttonRight.y = save.rightY; }
	}

	function saveAndClose()
	{
		bindButton = null;
		Options.mobilecontrols = options[curSelected];
		FlxG.save.data.mobileControlsMode = options[curSelected];
		FlxG.save.flush();
		close();
	}

	public function changeSelection(change:Int, force:Bool = false)
	{
		if (change == 0 && !force) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		modeText.text = "< " + options[curSelected] + " >";
		modeText.screenCenter(X);
		updatePreview();
	}

	function updatePreview()
	{
		if (isCustomizing) return;

		previewBox.visible = false;
		previewBox.forEachAlive(function(btn:FlxSprite) {
			btn.visible = false;
			btn.alpha = 0.2;
		});

		setPadEnabled(previewPad, false);
		setPadEnabled(previewDoublePad, false);
		setPadEnabled(customPad, false);

		switch (options[curSelected])
		{
			case 'Hitbox':
				previewBox.visible = true;
				previewBox.forEachAlive(function(btn:FlxSprite) {
					btn.visible = true;
				});
			case 'Dpad':
				setPadEnabled(previewPad, true, 0.5);
			case 'Double Dpad':
				setPadEnabled(previewDoublePad, true, 0.5);
			case 'Custom':
				setPadEnabled(customPad, true, 0.5);
			case 'None':
		}
	}

	override function destroy()
	{
		for (pad in hiddenPads)
		{
			if (pad != null)
			{
				pad.visible = true;
				pad.active = true;
				pad.blockInput = false;
			}
		}

		bindButton = null;

		if (FlxG.cameras.list.contains(subCam))
			FlxG.cameras.remove(subCam, true);

		super.destroy();
	}
}
#end
