import funkin.game.Strum;
import funkin.options.Options;
import funkin.game.PlayState;

var opponentNoteAlpha:Float = 0.4;
var laneBGs:Array<Dynamic> = [];
var strumLines = PlayState.instance.strumLines;

function postCreate() {
    for (i in 0...2) {
        var strumLine = strumLines.members[i];

        if (strumLine != null) {
            for (j in 0...4) {
                var receptor = strumLine.members[j];

                if (receptor != null) {
                    var bg = new FlxSprite(0, 0);
                   
                    bg.makeGraphic(105, FlxG.height, 0xFF000000);
                    bg.alpha = Options.strumlineBackground;
                    bg.cameras = [PlayState.instance.camHUD];
                    bg.scrollFactor.set(0, 0);

                    PlayState.instance.insert(PlayState.instance.members.indexOf(strumLines), bg);

                    laneBGs.push({
                        bg: bg,
                        receptor: receptor
                    });
                }
            }
        }
    }
}

function update(elapsed) {
    if (PlayState.instance == null) {
        return;
    }
    for (item in laneBGs) {
        item.bg.x = item.receptor.x + (item.receptor.width / 2) - (item.bg.width / 2);
    }
    
    if (Options.middleScroll) {
        for (strumLine in strumLines.members)
        {
            if (!strumLine.opponentSide) continue;

            strumLine.notes.forEach(function(note)
            {
                note.alpha = opponentNoteAlpha;
            });
        }
    }
}

function postUpdate(elapsed:Float) {
    if (PlayState.instance == null) {
        return;
    }
    if (Options.middleScroll) {
        var oppStrums = strumLines.members[0];
        if (oppStrums != null) {
            for (i in 0...oppStrums.members.length) {
                var strum = oppStrums.members[i];
                strum.alpha = opponentNoteAlpha;
                
                if (i < 2) {
                    strum.x = 92 + (112 * i);
                } else {
                    strum.x = FlxG.width - 316 + (112 * (i - 2));
                }
            }
        }
        
        var playerStrums = strumLines.members[1];
        if (playerStrums != null) {
            for (i in 0...playerStrums.members.length) {
                var strum = playerStrums.members[i];
                strum.x = 416 + (112 * i);
            }
        }
    }
}
