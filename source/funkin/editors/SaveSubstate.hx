package funkin.editors;

import haxe.io.Path;
import lime.ui.FileDialog;

#if android
import extension.androidtools.Tools;
import extension.androidtools.widget.Toast;
#end

class SaveSubstate extends MusicBeatSubstate {
	public var saveOptions:Map<String, Bool>;
	public var options:SaveSubstateData;

	public var data:String;

	public var cam:FlxCamera;

	public function new(data:String, ?options:SaveSubstateData, ?saveOptions:Map<String, Bool>) {
		super();
		this.data = data;

		if (saveOptions == null)
			saveOptions = [];
		this.saveOptions = saveOptions;

		if (options != null)
			this.options = options;
	}

	public override function create() {
		super.create();

		#if android
		var fileName:String = options.defaultSaveFile != null ? options.defaultSaveFile : "file.txt";
		var tempPath:String = haxe.io.Path.join([lime.system.System.applicationStorageDirectory, fileName]);
		
		try {
			sys.io.File.saveContent(tempPath, data);
			
			var ext:String = Path.extension(fileName).toLowerCase();
			var mimeType:String = "*/*";
			
			if (ext == "json") mimeType = "application/json";
			else if (ext == "xml" || ext == "hx" || ext == "lua" || ext == "txt") mimeType = "text/plain";
			
			Tools.saveFile(tempPath, fileName, mimeType, function(success:Bool) {
				if (success) {
					Toast.makeText("Saved File!", Toast.LENGTH_SHORT).show();
				}
				close();
			});
		} catch(e:Dynamic) {
			trace("Error writing temp save file for Android: " + e);
			Toast.makeText("Error saving file!", Toast.LENGTH_SHORT).show();
			close();
		}
		#else
		var fileDialog = new FileDialog();
		fileDialog.onCancel.add(function() close());
		fileDialog.onSelect.add(function(str) {
			CoolUtil.safeSaveFile(str, data);
			close();
		});
		fileDialog.browse(SAVE, options.saveExt.getDefault(Path.extension(options.defaultSaveFile)), options.defaultSaveFile);
		#end
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		parent.persistentUpdate = false;
	}
}

typedef SaveSubstateData = {
	var ?defaultSaveFile:String;
	var ?saveExt:String;
}
