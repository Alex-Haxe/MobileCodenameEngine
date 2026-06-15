package mobile.ui.menus;

import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;

// originally made by rhe official dev team of fnf
class FunkinBackButton extends FunkinButton
{
  public static function add(x:Float = 0, y:Float = 0, ?color:FlxColor = FlxColor.WHITE, ?confirmCallback:Void->Void, ?restingOpacity:Float = 0.3, instant:Bool = false):FunkinBackButton
  {
    var btn = new FunkinBackButton(x, y, color, confirmCallback, restingOpacity, instant);
    FlxG.state.add(btn);
    return btn;
  }

  public var onConfirmStart(default, null):FlxSignal = new FlxSignal();
  public var onConfirmEnd(default, null):FlxSignal = new FlxSignal();

  public var enabled:Bool = true;

  public var confirming(get, never):Bool;

  function get_confirming():Bool
  {
    return _confirming;
  }

  var _confirming:Bool = false;
  var _releaseBackspace:Bool = false;

  public var restingOpacity:Float;
  var instant:Bool = false;

  public function new(?x:Float = 0, ?y:Float = 0, ?color:FlxColor = FlxColor.WHITE, ?confirmCallback:Void->Void, ?restingOpacity:Float = 0.3,
      instant:Bool = false):Void
  {
    super(x, y);

    frames = Paths.getSparrowAtlas("menus/backButton");

    animation.addByIndices('idle', 'back', [0], "", 24, false);
    animation.addByIndices('hold', 'back', [5], "", 24, false);
    animation.addByIndices('confirm', 'back', [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22], "", 24, false);
    
    animation.play("idle");

    scale.set(0.7, 0.7);
    updateHitbox();

    this.color = color;
    this.restingOpacity = restingOpacity;
    this.instant = instant;
    this.alpha = restingOpacity;

    onUp.callback = playConfirmAnim;
    onDown.callback = playHoldAnim;
    onOut.callback = playOutAnim;

    if (confirmCallback != null)
    {
      onConfirmEnd.add(confirmCallback);
    }
  }

  override function updateStatusAnimation():Void
  {
  }

  function playHoldAnim():Void
  {
    if (confirming || !enabled) return;

    FlxTween.cancelTweensOf(this);
    animation.play('hold');
    alpha = 1;
  }

  function playConfirmAnim():Void
  {
    if (!enabled || confirming) return;

    if (instant)
    {
      triggerFakeBackspace();
      onConfirmEnd.dispatch();
      return;
    }

    _confirming = true;

    FlxTween.cancelTweensOf(this);
    animation.play('confirm');

    if (FlxG.sound != null) FlxG.sound.play(Paths.sound('cancelMenu'));

    onConfirmStart.dispatch();

    new FlxTimer().start(0.7, function(tmr:FlxTimer)
    {
      if (this.exists) {
        triggerFakeBackspace();
        onConfirmEnd.dispatch();
        _confirming = false;
      }
    });
  }

  function triggerFakeBackspace():Void 
  {
    FlxG.keys.handleAction(FlxKey.BACKSPACE, true);
    _releaseBackspace = true;
  }

  function playOutAnim():Void
  {
    if (confirming || !enabled) return;

    FlxTween.cancelTweensOf(this);
    animation.play('idle');

    FlxTween.tween(this, {alpha: restingOpacity}, 0.5, {
      ease: FlxEase.expoOut
    });
  }

  public function resetCallbacks():Void
  {
    onUp.callback = playConfirmAnim;
    onDown.callback = playHoldAnim;
    onOut.callback = playOutAnim;

    _confirming = false;
  }

  override public function update(elapsed:Float):Void
  {
    #if android
    if (FlxG.android.justReleased.BACK) onConfirmEnd.dispatch();
    #end

    if (_releaseBackspace)
    {
      FlxG.keys.handleAction(FlxKey.BACKSPACE, false);
      _releaseBackspace = false;
    }

    super.update(elapsed);
  }

  override public function destroy():Void
  {
    super.destroy();

    onConfirmStart.removeAll();
    onConfirmEnd.removeAll();
  }
}
