package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
import funkin.backend.assets.Paths;

class BackButton extends FlxSprite {
    
    var isPressingBack:Bool = false;
    var canClick:Bool = true;

    public function new(x:Float = 975, y:Float = 455, ?buttonCam:FlxCamera) {
        super(x, y);

        frames = Paths.getSparrowAtlas('backButton');
        
        animation.addByPrefix('idle', 'back0000', 24, true);
        animation.addByPrefix('clicked', 'back', 24, false);
        animation.play('idle');
        
        scale.set(0.85, 0.85);
        updateHitbox();
        
        scrollFactor.set(0, 0); 
        
        if (buttonCam != null) {
            this.cameras = [buttonCam];
        }
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (canClick && FlxG.mouse.overlaps(this, this.camera) && FlxG.mouse.justPressed) {
            canClick = false;
            isPressingBack = true;
            animation.play('clicked', true);
            
            FlxG.keys.handleAction(FlxKey.BACKSPACE, true);
        }

        if (isPressingBack && FlxG.mouse.justReleased) {
            isPressingBack = false;
            
            FlxG.keys.handleAction(FlxKey.BACKSPACE, false);
        }

        if (animation.curAnim != null && animation.curAnim.name == 'clicked' && animation.curAnim.finished) {
            animation.play('idle');
            canClick = true; 
        }
    }
}
