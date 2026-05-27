package funkin.options.type;

import flixel.FlxG;

class MobileControlsOption extends ArrayOption
{
	public function new()
	{
		super(
			'optionsTree.mobilecontrols-name',
			'optionsTree.mobilecontrols-desc',
			['Hitbox', 'Dpad', 'Double Dpad', 'Custom', 'None'],
			['Hitbox', 'Dpad', 'Double Dpad', 'Custom', 'None'],
			'mobilecontrols'
		);
	}

	override function select()
	{
		super.select();
		FlxG.state.openSubState(new funkin.menus.MobileControlsSubstate());
	}
}
