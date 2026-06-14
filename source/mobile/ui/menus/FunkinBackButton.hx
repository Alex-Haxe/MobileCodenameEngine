package mobile.ui.menus;

import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import flixel.input.keyboard.FlxKey;
import mobile.ui.FunkinButton;

// original by the official fnf dev team
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
    this.ignoreDownHandler = true;

    onUp.add(playConfirmAnim);
    onDown.add(playHoldAnim);
    onOut.add(playOutAnim);

    onConfirmEnd.add(confirmCallback);
  }

  function playHoldAnim():Void
  {
    if (confirming || held || !enabled) return;

    held = true;
    FlxG.keys.handleAction(FlxKey.BACKSPACE, true);

    FlxTween.cancelTweensOf(this);
    animation.play('hold');

    alpha = 1;
  }

  function playConfirmAnim():Void
  {
    if (!enabled) return;

    FlxG.keys.handleAction(FlxKey.BACKSPACE, false);

    if (instant)
    {
      onConfirmEnd.dispatch();
      return;
    }
    else if (confirming)
    {
      return;
    }

    _confirming = true;

    FlxTween.cancelTweensOf(this);
    animation.play('confirm');

    if (FlxG.sound != null) FlxG.sound.play(Paths.sound('cancelMenu'));

    onConfirmStart.dispatch();

    animation.onFinish.addOnce(function(name:String)
    {
      if (name != 'confirm') return;
      _confirming = false;
      held = false;
      onConfirmEnd.dispatch();
    });
  }

  function playOutAnim():Void
  {
    if (confirming || !enabled) return;

    if (held)
    {
      FlxG.keys.handleAction(FlxKey.BACKSPACE, false);
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
    onUp.removeAll();
    onDown.removeAll();
    onOut.removeAll();

    _confirming = false;
    held = false;

    onUp.add(playConfirmAnim);
    onDown.add(playHoldAnim);
    onOut.add(playOutAnim);
  }

  override public function update(elapsed:Float):Void
  {
    #if android
    if (FlxG.android.justReleased.BACK) onConfirmEnd.dispatch();
    #end

    super.update(elapsed);
  }

  override function destroy():Void
  {
    super.destroy();

    onConfirmStart.removeAll();
    onConfirmEnd.removeAll();

    if (animation != null && animation.onFinish != null) animation.onFinish.removeAll();
  }
}
