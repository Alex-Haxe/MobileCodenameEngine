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
			'mobileControlsMode'
		);
	}

	override function select()
	{
		FlxG.state.openSubState(new funkin.menus.MobileControlsSubstate());
	}
}
