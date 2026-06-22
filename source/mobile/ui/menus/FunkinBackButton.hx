package mobile.ui.menus;

#if mobile
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import flixel.input.keyboard.FlxKey;
import flixel.input.FlxInput.FlxInputState;
import mobile.ui.FunkinButton;
/**
class FunkinBackButton extends FunkinButton
{
  public static var buttonCam:FlxCamera;

  public var onConfirmStart(default, null):FlxSignal = new FlxSignal();
  public var onConfirmEnd(default, null):FlxSignal = new FlxSignal();

  public var enabled:Bool = true;

  public var confirming(get, never):Bool;

  function get_confirming():Bool
  {
    return _confirming;
  }

  var _confirming:Bool = false;
  public var restingOpacity:Float;

  var instant:Bool = false;
  var clickCooldown:Float = 0;
  
  var _triggerKeyRelease:Bool = false;

  public static function add(?x:Float = 0, ?y:Float = 0, ?color:FlxColor = FlxColor.WHITE, ?confirmCallback:Void->Void, ?restingOpacity:Float = 0.3, instant:Bool = false):FunkinBackButton
  {
    var btn = new FunkinBackButton(x, y, color, confirmCallback, restingOpacity, instant);
    FlxG.state.add(btn);
    return btn;
  }

  public function new(?x:Float = 0, ?y:Float = 0, ?color:FlxColor = FlxColor.WHITE, ?confirmCallback:Void->Void, ?restingOpacity:Float = 0.3,
      instant:Bool = false):Void
  {
    super(x, y);

    if (buttonCam == null || !FlxG.cameras.list.contains(buttonCam))
    {
      buttonCam = new FlxCamera();
      buttonCam.bgColor = FlxColor.TRANSPARENT;
      FlxG.cameras.add(buttonCam, false);
    }
    
    this.cameras = [buttonCam];

    frames = Paths.getSparrowAtlas("menus/backButton");
    animation.addByIndices('idle', 'back', [0], "", 24, false);
    animation.addByIndices('hold', 'back', [5], "", 24, false);
    animation.addByIndices('confirm', 'back', [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22], "", 24, false);
    animation.play("idle", true);

    scale.set(0.7, 0.7);
    updateHitbox();

    this.color = color;
    this.restingOpacity = restingOpacity;
    this.instant = instant;
    this.alpha = restingOpacity;

    if (confirmCallback != null) onConfirmEnd.add(confirmCallback);
  }

  override function onDownHandler():Void
  {
    super.onDownHandler();
    
    if (enabled && clickCooldown <= 0 && !_confirming)
    {
      @:privateAccess
      {
        if (FlxG.keys._keyListMap.exists(FlxKey.BACKSPACE)) {
          FlxG.keys._keyListMap[FlxKey.BACKSPACE].current = FlxInputState.JUST_PRESSED;
        }
      }
      _triggerKeyRelease = true;
      playConfirmAnim();
    }
  }

  function playConfirmAnim():Void
  {
    if (!enabled || confirming) return;

    _confirming = true;
    clickCooldown = 0.5;

    FlxTween.cancelTweensOf(this);
    animation.play('confirm', true);
    alpha = 1;

    FlxG.sound.play(Paths.sound('cancelMenu'));

    onConfirmStart.dispatch();

    if (instant)
    {
      onConfirmEnd.dispatch();
    }
  }

  function playOutAnim():Void
  {
    if (!enabled) return;

    FlxTween.cancelTweensOf(this);
    animation.play('idle', true);

    FlxTween.tween(this, {alpha: restingOpacity}, 0.5, {
      ease: FlxEase.expoOut
    });
  }

  public function resetCallbacks():Void
  {
    _confirming = false;
    clickCooldown = 0;
    _triggerKeyRelease = false;
    
    @:privateAccess
    {
      if (FlxG.keys._keyListMap.exists(FlxKey.BACKSPACE)) {
        FlxG.keys._keyListMap[FlxKey.BACKSPACE].current = FlxInputState.RELEASED;
      }
    }
  }

  override public function update(elapsed:Float):Void
  {
    if (clickCooldown > 0) clickCooldown -= elapsed;

    if (_triggerKeyRelease)
    {
      @:privateAccess
      {
        if (FlxG.keys._keyListMap.exists(FlxKey.BACKSPACE)) {
          FlxG.keys._keyListMap[FlxKey.BACKSPACE].current = FlxInputState.JUST_RELEASED;
        }
      }
      _triggerKeyRelease = false;
    }

    super.update(elapsed);

    if (FlxG.keys.justPressed.BACKSPACE && !_confirming) 
    {
      playConfirmAnim();
    }

    if (_confirming && animation.curAnim != null && animation.curAnim.name == 'confirm' && animation.finished)
    {
      _confirming = false;
      
      if (!instant) 
      {
        onConfirmEnd.dispatch();
      }
      
      playOutAnim();
    }
  }

  override function destroy():Void
  {
    super.destroy();

    onConfirmStart.removeAll();
    onConfirmEnd.removeAll();
  }
}
**/
#end
