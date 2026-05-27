package funkin.menus;

#if mobile
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import mobile.controls.VirtualPad;
import mobile.controls.HitBox;
import mobile.controls.FlxButton;
import funkin.backend.assets.Paths;
import funkin.options.Options;

class MobileControlsSubstate extends MusicBeatSubstate 
{
	var options:Array<String> = ['Hitbox', 'Dpad', 'Double Dpad', 'Custom', 'None'];
	var alphabets:FlxTypedGroup<Alphabet>;
	var curSelected:Int = 0;

	var subCam:FlxCamera;
	var bg:FlxSprite;

	var previewBox:HitBox;
	var previewPad:VirtualPad;
	var menuButtons:VirtualPad;

	var isCustomizing:Bool = false;
	var customPad:VirtualPad;
	var draggedButton:MobileButton;
	var dragOffset:FlxPoint = FlxPoint.get();

	public override function create() 
	{
		super.create();

		camera = subCam = new FlxCamera();
		subCam.bgColor = 0;
		FlxG.cameras.add(subCam, false);

		bg = new FlxSprite(0, 0).makeSolid(FlxG.width, FlxG.height, 0xFF000000);
		bg.updateHitbox();
		bg.scrollFactor.set();
		add(bg);

		bg.alpha = 0;
		FlxTween.tween(bg, {alpha: 0.85}, 0.25, {ease: FlxEase.cubeOut});

		previewBox = new HitBox(Options.hitboxStyle, Options.hintStyle);
		previewBox.alpha = 0.5;
		previewBox.visible = false;
		add(previewBox);

		previewPad = new VirtualPad(FULL, A_B_X_Y);
		previewPad.alpha = 0.5;
		previewPad.visible = false;
		add(previewPad);

		menuButtons = new VirtualPad(NONE, A_B);
		add(menuButtons);

		alphabets = new FlxTypedGroup<Alphabet>();
		
		for (i in 0...options.length) 
		{
			var a = new Alphabet(0, 0, options[i], true);
			a.isMenuItem = true;
			a.scrollFactor.set();
			alphabets.add(a);
		}
		add(alphabets);

		curSelected = 0;
		if (FlxG.save.data.mobileControlsMode != null) 
		{
			var idx = options.indexOf(FlxG.save.data.mobileControlsMode);
			if (idx != -1) curSelected = idx;
		}

		changeSelection(0, true);

		customPad = new VirtualPad(FULL, NONE); 
		customPad.visible = false;
		add(customPad);
	}

	public override function update(elapsed:Float) 
	{
		super.update(elapsed);

		if (!isCustomizing) 
		{
			var touchedItem = false;
			for (touch in FlxG.touches.list) 
			{
				if (touch.justPressed) 
				{
					for (i in 0...alphabets.length) 
					{
						var a = alphabets.members[i];
						if (a.overlapsPoint(touch.getWorldPosition(subCam), true, subCam)) 
						{
							if (curSelected != i) 
							{
								changeSelection(i - curSelected);
							} 
							else 
							{
								acceptSelection();
							}
							touchedItem = true;
							break;
						}
					}
				}
			}

			if (!touchedItem) 
			{
				var shift = (controls.LEFT_P ? 1 : 0) + (controls.RIGHT_P ? -1 : 0) - FlxG.mouse.wheel;
				if (shift != 0) changeSelection(shift);
			}

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

			if (customPad.buttonA != null && customPad.buttonA.justPressed) 
			{
				saveCustomLayout();
				saveAndClose();
			}

			if (customPad.buttonB != null && customPad.buttonB.justPressed) 
			{
				isCustomizing = false;
				customPad.visible = false;
				alphabets.visible = true;
				menuButtons.visible = true;
				loadCustomLayout(); 
				changeSelection(0, true);
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
		alphabets.visible = false;
		menuButtons.visible = false;
		
		previewBox.visible = false;
		previewPad.visible = false;

		customPad = new VirtualPad(FULL, A_B);
		customPad.visible = true;
		customPad.alpha = 1;
		loadCustomLayout();
	}

	function handleCustomDrag() 
	{
		var pointerPressed = false;
		var pointerJustPressed = false;
		var touchX:Float = 0;
		var touchY:Float = 0;

		var padCam = customPad.virtualpadCamera; 

		var touchFound = false;
		for (touch in FlxG.touches.list) 
		{
			pointerPressed = touch.pressed;
			pointerJustPressed = touch.justPressed;
			var pos = touch.getWorldPosition(padCam);
			touchX = pos.x;
			touchY = pos.y;
			pos.put();
			touchFound = true;
			break; 
		}

		if (!touchFound) 
		{
			pointerPressed = FlxG.mouse.pressed;
			pointerJustPressed = FlxG.mouse.justPressed;
			var pos = FlxG.mouse.getWorldPosition(padCam);
			touchX = pos.x;
			touchY = pos.y;
			pos.put();
		}

		var touchPoint = FlxPoint.get(touchX, touchY);

		if (pointerJustPressed) 
		{
			var buttons = [customPad.buttonUp, customPad.buttonDown, customPad.buttonLeft, customPad.buttonRight];
			for (btn in buttons) 
			{
				if (btn != null && btn.overlapsPoint(touchPoint, true, padCam)) 
				{
					draggedButton = btn;
					dragOffset.set(touchX - btn.x, touchY - btn.y);
					break;
				}
			}
		}

		if (pointerPressed && draggedButton != null) 
		{
			draggedButton.x = touchX - dragOffset.x;
			draggedButton.y = touchY - dragOffset.y;
		} 
		else if (!pointerPressed) 
		{
			draggedButton = null;
		}

		touchPoint.put();
	}

	function saveCustomLayout() 
	{
		if (FlxG.save.data.customPadPos == null) FlxG.save.data.customPadPos = {};
		
		if (customPad.buttonUp != null) {
			FlxG.save.data.customPadPos.upX = customPad.buttonUp.x;
			FlxG.save.data.customPadPos.upY = customPad.buttonUp.y;
		}
		if (customPad.buttonDown != null) {
			FlxG.save.data.customPadPos.downX = customPad.buttonDown.x;
			FlxG.save.data.customPadPos.downY = customPad.buttonDown.y;
		}
		if (customPad.buttonLeft != null) {
			FlxG.save.data.customPadPos.leftX = customPad.buttonLeft.x;
			FlxG.save.data.customPadPos.leftY = customPad.buttonLeft.y;
		}
		if (customPad.buttonRight != null) {
			FlxG.save.data.customPadPos.rightX = customPad.buttonRight.x;
			FlxG.save.data.customPadPos.rightY = customPad.buttonRight.y;
		}
		
		FlxG.save.flush();
	}

	function loadCustomLayout() 
	{
		var savedPos = FlxG.save.data.customPadPos;
		if (savedPos != null) 
		{
			if (savedPos.upX != null && customPad.buttonUp != null) customPad.buttonUp.x = savedPos.upX;
			if (savedPos.upY != null && customPad.buttonUp != null) customPad.buttonUp.y = savedPos.upY;
			if (savedPos.downX != null && customPad.buttonDown != null) customPad.buttonDown.x = savedPos.downX;
			if (savedPos.downY != null && customPad.buttonDown != null) customPad.buttonDown.y = savedPos.downY;
			if (savedPos.leftX != null && customPad.buttonLeft != null) customPad.buttonLeft.x = savedPos.leftX;
			if (savedPos.leftY != null && customPad.buttonLeft != null) customPad.buttonLeft.y = savedPos.leftY;
			if (savedPos.rightX != null && customPad.buttonRight != null) customPad.buttonRight.x = savedPos.rightX;
			if (savedPos.rightY != null && customPad.buttonRight != null) customPad.buttonRight.y = savedPos.rightY;
		}
	}

	function saveAndClose() 
	{
		FlxG.save.data.mobileControlsMode = options[curSelected];
		FlxG.save.flush();
		close();
	}

	public function changeSelection(change:Int, force:Bool = false) 
	{
		if (change == 0 && !force) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, alphabets.length - 1);

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4); 

		for (k => alphabet in alphabets.members) 
		{
			alphabet.alpha = 0.6;
			alphabet.targetY = k - curSelected;

			if (k == curSelected) {
				alphabet.alpha = 1;
				alphabet.text = "< " + options[k] + " >";
			} else {
				alphabet.text = options[k];
			}
		}

		updatePreview();
	}

	function updatePreview() 
	{
		if (isCustomizing) return;

		previewBox.visible = false;
		previewPad.visible = false;
		customPad.visible = false;

		var curOption = options[curSelected];
		
		if (curOption == 'Hitbox') 
		{
			previewBox.visible = true;
		} 
		else if (curOption == 'Dpad' || curOption == 'Double Dpad') 
		{
			previewPad.visible = true;
		}
		else if (curOption == 'Custom') 
		{
			customPad.alpha = 0.5;
			customPad.visible = true; 
		}
	}

	override function destroy() 
	{
		super.destroy();

		if (FlxG.cameras.list.contains(subCam))
			FlxG.cameras.remove(subCam);
	}
}
#end
