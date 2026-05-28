package funkin.menus;

#if mobile
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import mobile.controls.VirtualPad;
import mobile.controls.HitBox;
import mobile.controls.FlxButton;
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
	var menuButtons:VirtualPad;

	var isCustomizing:Bool = false;
	var customPad:VirtualPad;
	var draggedButton:MobileButton;
	var dragOffset:FlxPoint = FlxPoint.get();
	
	var waitFrames:Int = 0;
	var hiddenPads:Array<VirtualPad> = [];

	private function setupPadCamera(pad:VirtualPad):Void {
		if (pad == null) return;
		if (pad.virtualpadCamera != null) {
			FlxG.cameras.remove(pad.virtualpadCamera, true);
			pad.virtualpadCamera = null;
		}
		pad.cameras = [subCam];
	}

	public override function create() 
	{
		super.create();

		for (pad in VirtualPad.activePads) {
			if (pad != null && pad.visible) {
				pad.visible = false;
				pad.active = false;
				hiddenPads.push(pad);
			}
		}

		camera = subCam = new FlxCamera();
		subCam.bgColor = 0;
		FlxG.cameras.add(subCam, false);

		bg = new FlxSprite(0, 0).makeSolid(FlxG.width, FlxG.height, 0xFF000000);
		bg.updateHitbox();
		bg.scrollFactor.set();
		add(bg);

		bg.alpha = 0;
		FlxTween.tween(bg, {alpha: 0.85}, 0.25, {ease: FlxEase.cubeOut});

		curSelected = 0;
		if (FlxG.save.data.mobileControlsMode != null) 
		{
			var idx = options.indexOf(FlxG.save.data.mobileControlsMode);
			if (idx != -1) curSelected = idx;
		}

		modeText = new Alphabet(0, 40, "< " + options[curSelected] + " >", true);
		modeText.isMenuItem = false;
		modeText.screenCenter(X);
		add(modeText);

		previewBox = new HitBox(Options.hitboxStyle, Options.hintStyle);
		add(previewBox);
		previewBox.setupCamera();
		previewBox.visible = false;
		previewBox.active = false;

		previewPad = new VirtualPad(FULL, A_B_X_Y);
		setupPadCamera(previewPad);
		previewPad.alpha = 0.5;
		previewPad.active = false;
		add(previewPad);

		menuButtons = new VirtualPad(NONE, A_B);
		setupPadCamera(menuButtons);
		add(menuButtons);

		customPad = new VirtualPad(FULL, NONE); 
		setupPadCamera(customPad);
		customPad.visible = false;
		customPad.active = false;
		add(customPad);

		changeSelection(0, true);
	}

	public override function update(elapsed:Float) 
	{
		super.update(elapsed);

		if (waitFrames < 2) 
		{
			waitFrames++;
			return;
		}

		if (!isCustomizing) 
		{
			var touchedItem = false;
			
			for (touch in FlxG.touches.list) 
			{
				if (touch.justPressed) 
				{
					var touchPos = touch.getWorldPosition(subCam);
					if (touchPos.y < 150) 
					{
						if (touchPos.x < FlxG.width / 2) changeSelection(-1);
						else changeSelection(1);
						
						touchedItem = true;
						break;
					}
				}
			}

			if (!touchedItem && FlxG.mouse.justPressed) 
			{
				var mousePos = FlxG.mouse.getWorldPosition(subCam);
				if (mousePos.y < 150) 
				{
					if (mousePos.x < FlxG.width / 2) changeSelection(-1);
					else changeSelection(1);
					touchedItem = true;
				}
			}

			if (!touchedItem) 
			{
				var shift = (controls.LEFT_P ? -1 : 0) + (controls.RIGHT_P ? 1 : 0);
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

			if (customPad != null && customPad.buttonA != null && customPad.buttonA.justPressed) 
			{
				saveCustomLayout();
				saveAndClose();
			}

			if (customPad != null && customPad.buttonB != null && customPad.buttonB.justPressed) 
			{
				isCustomizing = false;
				customPad.visible = false;
				customPad.active = false;
				modeText.visible = true;
				
				menuButtons.visible = true;
				menuButtons.active = true;
				
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
		modeText.visible = false;
		
		menuButtons.visible = false;
		menuButtons.active = false;
		
		if (previewBox != null) {
			previewBox.visible = false;
			previewBox.active = false;
		}
		if (previewPad != null) {
			previewPad.visible = false;
			previewPad.active = false;
		}

		if (customPad != null) 
		{
			remove(customPad);
			customPad.destroy();
		}

		customPad = new VirtualPad(FULL, A_B);
		setupPadCamera(customPad);
		customPad.visible = true;
		customPad.active = true;
		customPad.alpha = 1;
		add(customPad); 

		loadCustomLayout();
	}

	function handleCustomDrag() 
	{
		if (customPad == null) return;

		var pointerPressed = false;
		var pointerJustPressed = false;
		var touchX:Float = 0;
		var touchY:Float = 0;

		var padCam = (customPad.virtualpadCamera != null) ? customPad.virtualpadCamera : subCam; 

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
		if (customPad == null) return;
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
		if (customPad == null) return;
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
		
		if (Reflect.hasField(Options, "mobileControlsMode")) {
			Reflect.setProperty(Options, "mobileControlsMode", options[curSelected]);
		} else if (Reflect.hasField(Options, "mobileControls")) {
			Reflect.setProperty(Options, "mobileControls", options[curSelected]);
		}

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

		if (previewBox != null) {
			previewBox.visible = false;
			previewBox.active = false;
		}
		if (previewPad != null) {
			previewPad.visible = false;
			previewPad.active = false;
		}
		if (customPad != null) {
			customPad.visible = false;
			customPad.active = false;
		}

		var curOption = options[curSelected];
		
		if (curOption == 'Hitbox' && previewBox != null) 
		{
			previewBox.visible = true;
			previewBox.active = true;
		} 
		else if (curOption == 'Dpad' || curOption == 'Double Dpad') 
		{
			if (previewPad != null) 
			{
				remove(previewPad);
				previewPad.destroy();
			}

			var padMode = (curOption == 'Double Dpad') ? DOUBLE : FULL;
			previewPad = new VirtualPad(padMode, A_B_X_Y);
			setupPadCamera(previewPad);
			previewPad.alpha = 0.5;
			previewPad.active = false;
			add(previewPad);
		}
		else if (curOption == 'Custom' && customPad != null) 
		{
			customPad.alpha = 0.5;
			customPad.visible = true; 
			customPad.active = false;
		}
	}

	override function destroy() 
	{
		for (pad in hiddenPads) {
			if (pad != null) {
				pad.visible = true;
				pad.active = true;
			}
		}

		super.destroy();

		if (FlxG.cameras.list.contains(subCam))
			FlxG.cameras.remove(subCam);

		if (dragOffset != null) 
		{
			dragOffset.put();
			dragOffset = null;
		}

		subCam = null;
		bg = null;
		previewBox = null;
		previewPad = null;
		menuButtons = null;
		customPad = null;
		modeText = null;
		draggedButton = null;
	}
}
#end
