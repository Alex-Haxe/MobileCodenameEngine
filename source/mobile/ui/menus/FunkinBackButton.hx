package mobile.ui.menus;

#if mobile
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import flixel.input.keyboard.FlxKey;
import mobile.ui.FunkinButton;

class FunkinBackButton extends FunkinButton
{
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
  var held:Bool = false;
  
  var _sendPressNextFrame:Bool = false;
  var _sendReleaseNextFrame:Bool = false;

  public static var buttonCam:FlxCamera = null;

  public static function add(?x:Float = 0, ?y:Float = 0, ?color:FlxColor = FlxColor.WHITE, ?confirmCallback:Void->Void, ?restingOpacity:Float = 0.3, instant:Bool = false):FunkinBackButton
  {
    prepareCamera();
    var btn = new FunkinBackButton(x, y, color, confirmCallback, restingOpacity, instant);
    btn.cameras = [buttonCam];
    FlxG.state.add(btn);
    return btn;
  }

  public static function prepareCamera():Void
  {
    if (buttonCam == null)
    {
      buttonCam = new FlxCamera();
      buttonCam.bgColor = FlxColor.TRANSPARENT;
    }
    
    if (!FlxG.cameras.list.contains(buttonCam))
    {
      FlxG.cameras.add(buttonCam, false);
    }
  }

  public function new(?x:Float = 0, ?y:Float = 0, ?color:FlxColor = FlxColor.WHITE, ?confirmCallback:Void->Void, ?restingOpacity:Float = 0.3,
      instant:Bool = false):Void
  {
    super(x, y);

    frames = Paths.getSparrowAtlas("menus/backButton");
    animation.addByIndices('idle', 'back',, "", 24, false);
    animation.addByIndices('hold', 'back',, "", 24, false);
    animation.addByIndices('confirm', 'back',, "", 24, false);
    animation.play("idle");

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
    playHoldAnim();
  }

  override function onUpHandler():Void
  {
    super.onUpHandler();
    playConfirmAnim();
  }

  override function onOutHandler():Void
  {
    super.onOutHandler();
    playOutAnim();
  }

  function playHoldAnim():Void
  {
    if (confirming || held || !enabled) return;

    held = true;

    FlxTween.cancelTweensOf(this);
    animation.play('hold');

    alpha = 1;
    
    _sendPressNextFrame = true;
  }

  function playConfirmAnim():Void
  {
    if (!enabled || !held || confirming) return;

    _confirming = true;

    FlxTween.cancelTweensOf(this);
    animation.play('confirm');

    FlxG.sound.play(Paths.sound('cancelMenu'));

    onConfirmStart.dispatch();

    animation.onFinish.addOnce(function(name:String)
    {
      if (name != 'confirm') return;
      
      _sendReleaseNextFrame = true;
      onConfirmEnd.dispatch();
      
      _confirming = false;
      held = false;
    });
    
    if (instant)
    {
      _sendReleaseNextFrame = true;
      onConfirmEnd.dispatch();
      _confirming = false;
      held = false;
    }
  }

  function playOutAnim():Void
  {
    if (confirming || !enabled) return;

    if (held)
    {
      _sendReleaseNextFrame = true;
    }

    FlxTween.cancelTweensOf(this);
    animation.play('idle');

    FlxTween.tween(this, {alpha: restingOpacity}, 0.5, {
      ease: FlxEase.expoOut,
      onComplete: function(tween:FlxTween):Void
      {
        held = false;
      }
    });
  }

  public function resetCallbacks():Void
  {
    _confirming = false;
    held = false;
    _sendPressNextFrame = false;
    _sendReleaseNextFrame = false;
  }

  override public function update(elapsed:Float):Void
  {
    if (buttonCam != null && FlxG.cameras.list.indexOf(buttonCam) != FlxG.cameras.list.length - 1)
    {
      FlxG.cameras.remove(buttonCam, false);
      FlxG.cameras.add(buttonCam, false);
    }

    if (_sendPressNextFrame)
    {
      _sendPressNextFrame = false;
      FlxG.keys.handleAction(FlxKey.BACKSPACE, true);
    }
    
    if (_sendReleaseNextFrame)
    {
      _sendReleaseNextFrame = false;
      FlxG.keys.handleAction(FlxKey.BACKSPACE, false);
    }

    super.update(elapsed);

    #if android
    if (FlxG.android.justPressed.BACK) 
    {
      playHoldAnim();
    }
    #end
  }

  override function destroy():Void
  {
    super.destroy();

    onConfirmStart.removeAll();
    onConfirmEnd.removeAll();

    if (animation != null && animation.onFinish != null) animation.onFinish.removeAll();
  }
}
#end
