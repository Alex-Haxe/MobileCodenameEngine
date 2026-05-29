package funkin.menus;

#if mobile
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import mobile.controls.VirtualPad;
import mobile.controls.HitBox;
import funkin.backend.assets.Paths;
import funkin.options.Options;

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

	var draggedButton:FlxSprite;
	var dragOffset:FlxPoint = FlxPoint.get();

	var hiddenPads:Array<VirtualPad> = [];

	private function setupPadCamera(pad:VirtualPad):Void
	{
		if (pad == null) return;

		if (pad.virtualpadCamera != null)
		{
			FlxG.cameras.remove(pad.virtualpadCamera, true);
			pad.virtualpadCamera = null;
		}

		pad.cameras = [subCam];
	}

	function setPadEnabled(pad:VirtualPad, enabled:Bool)
	{
		if (pad == null) return;

		pad.visible = enabled;
		pad.active = enabled;

		var buttons = [
			pad.buttonUp,
			pad.buttonDown,
			pad.buttonLeft,
			pad.buttonRight,
			pad.buttonUp2,
			pad.buttonDown2,
			pad.buttonLeft2,
			pad.buttonRight2,
			pad.buttonA,
			pad.buttonB,
			pad.buttonX,
			pad.buttonY
		];

		for (btn in buttons)
		{
			if (btn != null)
			{
				btn.visible = enabled;
				btn.active = enabled;
			}
		}
	}

	public override function create()
	{
		super.create();

		persistentUpdate = false;

		FlxG.mouse.reset();
		FlxG.touches.reset();

		for (pad in VirtualPad.activePads.copy())
		{
			if (pad == null) continue;

			pad.visible = false;
			pad.active = false;
			pad.blockInput = true;

			hiddenPads.push(pad);
		}

		camera = subCam = new FlxCamera();
		subCam.bgColor = 0;
		FlxG.cameras.add(subCam, false);

		bg = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF000000);
		bg.scrollFactor.set();
		add(bg);

		bg.alpha = 0;

		FlxTween.tween(bg, {alpha: 0.85}, 0.25, {
			ease: FlxEase.cubeOut
		});

		var savedMode:String = Options.mobilecontrols;

		if (savedMode != null)
		{
			var idx = options.indexOf(savedMode);

			if (idx != -1)
				curSelected = idx;
		}

		modeText = new Alphabet(0, 40, "", true);
		modeText.isMenuItem = false;
		add(modeText);

		previewBox = new HitBox(Options.hitboxStyle, Options.hintStyle);
		previewBox.setupCamera();
		previewBox.alpha = 0.5;
		previewBox.visible = false;
		previewBox.active = false;
		add(previewBox);

		previewPad = new VirtualPad(FULL, NONE);
		setupPadCamera(previewPad);
		previewPad.alpha = 0.5;
		add(previewPad);

		previewDoublePad = new VirtualPad(DOUBLE, NONE);
		setupPadCamera(previewDoublePad);
		previewDoublePad.alpha = 0.5;
		add(previewDoublePad);

		customPad = new VirtualPad(CUSTOM, NONE);
		setupPadCamera(customPad);
		customPad.alpha = 0.5;
		customPad.blockInput = true;
		add(customPad);

		menuButtons = new VirtualPad(NONE, A_B);
		setupPadCamera(menuButtons);
		add(menuButtons);

		menuButtons.blockInput = false;

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

			if (menuButtons.buttonA != null)
				stillPressed = stillPressed || menuButtons.buttonA.pressed;

			if (!stillPressed)
				acceptBlocked = false;

			return;
		}

		if (!isCustomizing)
		{
			var leftPressed = false;
			var rightPressed = false;

			for (touch in FlxG.touches.list)
			{
				if (!touch.justPressed)
					continue;

				var pos = touch.getWorldPosition(subCam);

				if (pos.y < 150)
				{
					if (pos.x < FlxG.width * 0.5)
						leftPressed = true;
					else
						rightPressed = true;
				}

				pos.put();
			}

			if (leftPressed || controls.LEFT_P)
				changeSelection(-1);
			else if (rightPressed || controls.RIGHT_P)
				changeSelection(1);

			if (controls.ACCEPT || (menuButtons.buttonA != null && menuButtons.buttonA.justPressed))
			{
				acceptSelection();
			}

			if (controls.BACK || (menuButtons.buttonB != null && menuButtons.buttonB.justPressed))
			{
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

				draggedButton = null;

				modeText.visible = true;

				customPad.blockInput = true;

				setPadEnabled(customPad, false);

				updatePreview();
			}
		}
	}

	function acceptSelection()
	{
		if (options[curSelected] == 'Custom')
		{
			enterCustomization();
		}
		else
		{
			saveAndClose();
		}
	}

	function enterCustomization()
	{
		isCustomizing = true;

		modeText.visible = false;

		previewBox.visible = false;

		setPadEnabled(previewPad, false);
		setPadEnabled(previewDoublePad, false);

		setPadEnabled(customPad, true);

		customPad.alpha = 1;
		customPad.blockInput = false;

		loadCustomLayout();
	}

	function handleCustomDrag()
	{
		var pointerPressed = false;
		var pointerJustPressed = false;

		var touchX:Float = 0;
		var touchY:Float = 0;

		for (touch in FlxG.touches.list)
		{
			pointerPressed = touch.pressed;
			pointerJustPressed = touch.justPressed;

			var pos = touch.getWorldPosition(subCam);

			touchX = pos.x;
			touchY = pos.y;

			pos.put();

			break;
		}

		if (!pointerPressed)
		{
			draggedButton = null;
			return;
		}

		var point = FlxPoint.get(touchX, touchY);

		if (pointerJustPressed)
		{
			var buttons = [
				customPad.buttonUp,
				customPad.buttonDown,
				customPad.buttonLeft,
				customPad.buttonRight
			];

			for (btn in buttons)
			{
				if (btn != null && btn.overlapsPoint(point, true, subCam))
				{
					draggedButton = btn;

					dragOffset.set(
						touchX - btn.x,
						touchY - btn.y
					);

					break;
				}
			}
		}

		if (draggedButton != null)
		{
			draggedButton.x = touchX - dragOffset.x;
			draggedButton.y = touchY - dragOffset.y;
		}

		point.put();
	}

	function saveCustomLayout()
	{
		if (FlxG.save.data.customPadPos == null)
			FlxG.save.data.customPadPos = {};

		var save = FlxG.save.data.customPadPos;

		save.upX = customPad.buttonUp.x;
		save.upY = customPad.buttonUp.y;

		save.downX = customPad.buttonDown.x;
		save.downY = customPad.buttonDown.y;

		save.leftX = customPad.buttonLeft.x;
		save.leftY = customPad.buttonLeft.y;

		save.rightX = customPad.buttonRight.x;
		save.rightY = customPad.buttonRight.y;

		FlxG.save.flush();
	}

	function loadCustomLayout()
	{
		var save = FlxG.save.data.customPadPos;

		if (save == null)
			return;

		if (save.upX != null)
		{
			customPad.buttonUp.x = save.upX;
			customPad.buttonUp.y = save.upY;
		}

		if (save.downX != null)
		{
			customPad.buttonDown.x = save.downX;
			customPad.buttonDown.y = save.downY;
		}

		if (save.leftX != null)
		{
			customPad.buttonLeft.x = save.leftX;
			customPad.buttonLeft.y = save.leftY;
		}

		if (save.rightX != null)
		{
			customPad.buttonRight.x = save.rightX;
			customPad.buttonRight.y = save.rightY;
		}
	}

	function saveAndClose()
	{
		draggedButton = null;

		Options.mobilecontrols = options[curSelected];

		FlxG.save.data.mobileControlsMode = options[curSelected];

		FlxG.save.flush();

		close();
	}

	public function changeSelection(change:Int, force:Bool = false)
	{
		if (change == 0 && !force)
			return;

		curSelected = FlxMath.wrap(
			curSelected + change,
			0,
			options.length - 1
		);

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		modeText.text = "< " + options[curSelected] + " >";
		modeText.screenCenter(X);

		updatePreview();
	}

	function updatePreview()
	{
		if (isCustomizing)
			return;

		previewBox.visible = false;

		setPadEnabled(previewPad, false);
		setPadEnabled(previewDoublePad, false);
		setPadEnabled(customPad, false);

		switch (options[curSelected])
		{
			case 'Hitbox':
				previewBox.visible = true;

			case 'Dpad':
				setPadEnabled(previewPad, true);

				previewPad.active = false;
				previewPad.alpha = 0.5;
				previewPad.blockInput = true;

			case 'Double Dpad':
				setPadEnabled(previewDoublePad, true);

				previewDoublePad.active = false;
				previewDoublePad.alpha = 0.5;
				previewDoublePad.blockInput = true;

			case 'Custom':
				setPadEnabled(customPad, true);

				customPad.alpha = 0.5;
				customPad.blockInput = true;

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

		draggedButton = null;

		if (dragOffset != null)
		{
			dragOffset.put();
			dragOffset = null;
		}

		if (FlxG.cameras.list.contains(subCam))
			FlxG.cameras.remove(subCam);

		super.destroy();
	}
}
#end
