package funkin.options.type;

import flixel.FlxG;

class MobileControlsOption extends ArrayOption
{
	public function new(text:String, desc:String)
	{
		super(
			text,
			desc,
			['Hitbox', 'Dpad', 'Double Dpad', 'Custom', 'None'],
			['Hitbox', 'Dpad', 'Double Dpad', 'Custom', 'None'],
			'mobilecontrols'
		);

		__selectionText.text = " >";
	}

	override function formatTextOption()
	{
		return " >";
	}

	override function changeSelection(change:Int)
  {
	}

	override function select()
	{
		FlxG.state.openSubState(new funkin.menus.MobileControlsSubstate());
	}
}
