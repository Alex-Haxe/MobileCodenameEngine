package funkin.backend.shaders;

import openfl.Assets;

@:deprecated("Use funkin.backend.shaders.FunkinShader.fromFile instead.")
class CustomShader extends FunkinShader {
	@:isVar
	public var path(get, set):String;
	inline function get_path():String return path != null ? path : _fragmentFilePath + _vertexFilePath;
	inline function set_path(v:Null<String>):String return path = cast v;

	/**
	 * Creates a new custom shader
	 * @param name Name of the frag and vert files.
	 */
	public function new(name:String) {
		var fragShaderPath = Paths.fragShader(name);
		var vertShaderPath = Paths.vertShader(name);
		
		var hasFrag = Assets.exists(fragShaderPath);
		var hasVert = Assets.exists(vertShaderPath);
		
		var fragCode = hasFrag ? Assets.getText(fragShaderPath) : null;
		var vertCode = hasVert ? Assets.getText(vertShaderPath) : null;

		this.fileName = name;
		this.fragFileName = fragShaderPath;
		this.vertFileName = vertShaderPath;

		this.path = name;

		if (fragCode == null && vertCode == null) {
			Logs.trace('Shader "$name" assets were not found. Falling back to default.', WARNING);
		}

		super(fragCode, vertCode);
	}
}
