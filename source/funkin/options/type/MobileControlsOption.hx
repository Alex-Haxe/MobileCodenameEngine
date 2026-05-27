package funkin.options.type;

import flixel.FlxG;

class MobileControlsOption extends ArrayOption
{
	public function new(name:String, desc:String)
	{
		super(
			name,
			desc,
			['Hitbox', 'Dpad', 'Double Dpad', 'Custom', 'None'],
			['Hitbox', 'Dpad', 'Double Dpad', 'Custom', 'None'],
			'mobilecontrols'
		);
	}

	override public function select()
	{
		super.select();

		FlxG.state.openSubState(new funkin.menus.MobileControlsSubstate());
	}
}
