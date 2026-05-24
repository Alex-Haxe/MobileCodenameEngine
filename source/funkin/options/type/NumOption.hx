package funkin.options.type;

class NumOption extends TextOption {
	public var changedCallback:Float->Void;

	public var min:Float;
	public var max:Float;
	public var step:Float;

	public var currentValue(default, set):Float;

	public var parent:Dynamic;
	public var optionName:String;

	var __number:Alphabet;
	var __left:Alphabet;
	var __right:Alphabet;

	function set_currentValue(v:Float):Float {
		if (__number != null)
			__number.text = ':';

		if (__left != null)
			__left.text = '<';

		if (__right != null)
			__right.text = '$v >';

		updateArrowPositions();

		return currentValue = v;
	}

	function updateArrowPositions() {
		if (__left != null && __number != null && __right != null) {
			__number.x = __text.x + __text.width + 12;
			__left.x = __number.x + __number.width + 8;
			__right.x = __left.x + __left.width + 8;

			__number.y = __text.y;
			__left.y = __text.y;
			__right.y = __text.y;
		}
	}

	override function set_text(v:String):String {
		super.set_text(v);
		updateArrowPositions();
		return v;
	}

	public function new(
		text:String,
		desc:String,
		min:Float,
		max:Float,
		step:Float = 1,
		?optionName:String,
		?changedCallback:Float->Void = null,
		?parent:Dynamic
	) {
		this.changedCallback = changedCallback;
		this.min = min;
		this.max = max;
		this.step = step;
		this.optionName = optionName;
		this.parent = parent != null ? parent : Options;

		if (Reflect.field(this.parent, optionName) != null)
			currentValue = Reflect.field(this.parent, optionName);
		else
			currentValue = min;

		__number = new Alphabet(0, 20, ':', 'bold');
		__left = new Alphabet(0, 20, '<', 'bold');
		__right = new Alphabet(0, 20, '$currentValue >', 'bold');

		super(text, desc);

		add(__number);
		add(__left);
		add(__right);

		updateArrowPositions();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.mouse.justPressed) {
			if (FlxG.mouse.overlaps(__left))
				changeValue(-1);

			if (FlxG.mouse.overlaps(__right))
				changeValue(1);
		}
	}

	function changeValue(change:Int) {
		if (locked) return;

		var old = currentValue;

		currentValue = FlxMath.bound(
			currentValue + change * step,
			min,
			max
		);

		if (old == currentValue)
			return;

		Reflect.setField(parent, optionName, currentValue);

		if (changedCallback != null)
			changedCallback(currentValue);

		CoolUtil.playMenuSFX(SCROLL);
	}

	override function changeSelection(change:Int):Void {
		changeValue(change);
	}

	override function select() {}
}
