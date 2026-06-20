package mobile.backend.assets;

using StringTools;

#if mobile
class Files
{
	#if android
	private static var _androidDir:String = null;

	private static function getAndroidStorageDir():String
	{
		if (_androidDir != null && _androidDir != "")
			return _androidDir;

		var dir:String = null;

		try {
			if (VERSION.SDK_INT >= VERSION_CODES.R)
			{
				dir = Context.getObbDir();
			}
			else
			{
				dir = Context.getExternalFilesDir();
			}
		} catch (e:Dynamic) {
		}

		if (dir == null || dir == "") 
		{
			dir = lime.system.System.documentsDirectory;
		}

		if (dir != null && dir != "") 
		{
			_androidDir = Path.addTrailingSlash(dir);
		} 
		else 
		{
			_androidDir = ""; 
		}

		return _androidDir;
	}
	#end
	
	public static function getAssetsDir():String
	{
		#if android
		return getAndroidStorageDir();
		#elseif ios
		var dir = lime.system.System.documentsDirectory;
		if (dir != null && !dir.endsWith("/")) dir += "/";
		return dir != null ? dir : "";
		#else
		return Sys.getCwd();
		#end
	}

	public static function getModsDir():String
	{
		#if android
		return getAndroidStorageDir();
		#elseif ios
		var dir = lime.system.System.documentsDirectory;
		if (dir != null && !dir.endsWith("/")) dir += "/";
		return dir != null ? dir : "";
		#else
		return Sys.getCwd();
		#end
	}
	
	public static function init():Void
	{
		try {
			var assetsBase = Path.addTrailingSlash(getAssetsDir());
			var modsBase = Path.addTrailingSlash(getModsDir());

			if (assetsBase == "/" || assetsBase == "") return;

			createDirRecursive(assetsBase);
			createDirRecursive(modsBase + "mods/");

			copyFolderOnce("assets", assetsBase + "assets/");
		} catch (e:Dynamic) {
		}
	}
	
	static function copyFolderOnce(folder:String, target:String):Void
	{
		#if sys
		try {
			if (FileSystem.exists(target))
			{
				return;
			}
		} catch (e:Dynamic) {
			return;
		}
		#end

		copyAssets(folder, target);
	}

	static function copyAssets(source:String, target:String):Void
	{
		try {
			var list:Array<String> = Assets.list();

			for (asset in list)
			{
				if (!asset.startsWith(source)) continue;

				var relative = asset.substr(source.length);
				if (relative.startsWith("/")) relative = relative.substr(1);

				var outPath = Path.addTrailingSlash(target) + relative;
				var dir = Path.directory(outPath);

				createDirRecursive(dir);

				try {
					var bytes:Bytes = Assets.getBytes(asset);

					if (bytes != null) {
						File.saveBytes(outPath, bytes);
					} else {
						var text:String = lime.utils.Assets.getText(asset);
						if (text != null) File.saveContent(outPath, text);
					}
				} catch (e:Dynamic) {
				}
			}
		} catch (e:Dynamic) {
		}
	}

	static function createDirRecursive(path:String):Void
	{
		#if sys
		if (path == null || path == "") return;

		try {
			path = Path.normalize(path);

			if (!FileSystem.exists(path)) {
				FileSystem.createDirectory(path);
			}
		} catch (e:Dynamic) {
		}
		#end
	}
}
#end
