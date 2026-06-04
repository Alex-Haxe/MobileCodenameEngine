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
import funkin.backend.utils.FunkinParentDisabler;
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
	var isDragging:Bool = false;

	var hiddenPads:Array<VirtualPad> = [];
	var oldParentUpdate:Bool = false;

	var leftArrow:Alphabet;
	var rightArrow:Alphabet;

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

		if (_parentState != null) {
			oldParentUpdate = _parentState.persistentUpdate;
			_parentState.persistentUpdate = false;
		}

		if (VirtualPad.activePads != null) {
			for (pad in VirtualPad.activePads.copy())
			{
				if (pad == null) continue;
				pad.visible = false;
				pad.active = false;
				hiddenPads.push(pad);
			}
		}

		camera = subCam = new FlxCamera();
		subCam.bgColor = 0;
		FlxG.cameras.add(subCam, false);

		bg = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF000000);
		bg.scrollFactor.set();
		bg.alpha = 0;
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

		leftArrow = new Alphabet(0, 40, "<", true);
		leftArrow.isMenuItem = false;
		leftArrow.cameras = [subCam];
		add(leftArrow);

		rightArrow = new Alphabet(0, 40, ">", true);
		rightArrow.isMenuItem = false;
		rightArrow.cameras = [subCam];
		add(rightArrow);

		previewBox = new HitBox(Options.hitboxStyle, Options.hintStyle);
		previewBox.setupCamera();
		previewBox.cameras = [subCam];
		previewBox.forEachAlive(function(btn:FlxSprite) {
			btn.cameras = [subCam];
		});
		previewBox.visible = false;
		previewBox.active = false;
		add(previewBox);

		previewPad = new VirtualPad(FULL, NONE);
		previewPad.blockInput = true;
		setupPadCamera(previewPad);
		add(previewPad);

		previewDoublePad = new VirtualPad(DOUBLE, NONE);
		previewDoublePad.blockInput = true;
		setupPadCamera(previewDoublePad);
		add(previewDoublePad);

		customPad = new VirtualPad(CUSTOM, NONE);
		customPad.blockInput = true;
		setupPadCamera(customPad);
		add(customPad);

		menuButtons = new VirtualPad(NONE, A_B);
		setupPadCamera(menuButtons);
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
			for (touch in FlxG.touches.list)
			{
				if (!touch.justPressed) continue;

				var pos = touch.getWorldPosition(subCam);
				
				if (pos.x >= leftArrow.x - 30 && pos.x <= leftArrow.x + leftArrow.width + 30 &&
					pos.y >= leftArrow.y - 30 && pos.y <= leftArrow.y + leftArrow.height + 30)
				{
					changeSelection(-1);
					pos.put();
					return;
				}
				
				if (pos.x >= rightArrow.x - 30 && pos.x <= rightArrow.x + rightArrow.width + 30 &&
					pos.y >= rightArrow.y - 30 && pos.y <= rightArrow.y + rightArrow.height + 30)
				{
					changeSelection(1);
					pos.put();
					return;
				}
				
				pos.put();
			}

			if (controls.LEFT_P) changeSelection(-1);
			else if (controls.RIGHT_P) changeSelection(1);

			if (controls.ACCEPT || (menuButtons.buttonA != null && menuButtons.buttonA.justPressed)) 
			{
				VirtualPad.inputBlockFrames = 2;
				FlxG.mouse.reset();
				FlxG.touches.reset();
				acceptSelection();
			}

			if (controls.BACK || (menuButtons.buttonB != null && menuButtons.buttonB.justPressed)) 
			{
				VirtualPad.inputBlockFrames = 2;
				FlxG.mouse.reset();
				FlxG.touches.reset();
				close();
			}
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
				isDragging = false;
				modeText.visible = true;
				leftArrow.visible = true;
				rightArrow.visible = true;
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
		leftArrow.visible = false;
		rightArrow.visible = false;
		previewBox.visible = false;

		setPadEnabled(previewPad, false);
		setPadEnabled(previewDoublePad, false);
		setPadEnabled(customPad, true, 1.0);

		loadCustomLayout();
	}

	function handleCustomDrag()
	{
		var pointerPressed:Bool = false;
		var pointerJustPressed:Bool = false;
		var pointerJustReleased:Bool = false;
		var pointerX:Float = 0;
		var pointerY:Float = 0;

		#if mobile
		for (touch in FlxG.touches.list) {
			pointerPressed = touch.pressed;
			pointerJustPressed = touch.justPressed;
			pointerJustReleased = touch.justReleased;
			pointerX = touch.getWorldPosition(subCam).x;
			pointerY = touch.getWorldPosition(subCam).y;
			break;
		}
		#else
		pointerPressed = FlxG.mouse.pressed;
		pointerJustPressed = FlxG.mouse.justPressed;
		pointerJustReleased = FlxG.mouse.justReleased;
		pointerX = FlxG.mouse.getWorldPosition(subCam).x;
		pointerY = FlxG.mouse.getWorldPosition(subCam).y;
		#end

		if (isDragging && bindButton != null)
		{
			if (pointerPressed)
			{
				bindButton.x = FlxMath.bound(pointerX - (bindButton.width / 2), 0, FlxG.width - bindButton.width);
				bindButton.y = FlxMath.bound(pointerY - (bindButton.height / 2), 0, FlxG.height - bindButton.height);
			}
			else if (pointerJustReleased)
			{
				bindButton = null;
				isDragging = false;
			}
		}
		else if (pointerJustPressed)
		{
			customPad.forEachAlive(function(btn:FlxSprite) {
				if (pointerX >= btn.x && pointerX <= btn.x + btn.width && 
					pointerY >= btn.y && pointerY <= btn.y + btn.height) 
				{
					bindButton = btn;
					isDragging = true;
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
		isDragging = false;
		Options.mobilecontrols = options[curSelected];
		FlxG.save.data.mobileControlsMode = options[curSelected];
		FlxG.save.flush();
		VirtualPad.inputBlockFrames = 2;
		FlxG.mouse.reset();
		FlxG.touches.reset();
		close();
	}

	public function changeSelection(change:Int, force:Bool = false)
	{
		if (change == 0 && !force) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		modeText.text = options[curSelected];
		modeText.screenCenter(X);

		leftArrow.x = modeText.x - leftArrow.width - 20;
		leftArrow.y = modeText.y;

		rightArrow.x = modeText.x + modeText.width + 20;
		rightArrow.y = modeText.y;

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
			}
		}

		bindButton = null;
		isDragging = false;

		if (FlxG.cameras.list.contains(subCam))
			FlxG.cameras.remove(subCam, true);

		if (_parentState != null) {
			_parentState.persistentUpdate = oldParentUpdate;
		}
		
		super.destroy();
	}
}
#end
