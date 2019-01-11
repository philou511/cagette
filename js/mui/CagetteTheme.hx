package mui;

import js.Object;

// This is not complete but exposes what we are currently using of the theme
typedef CagetteTheme = {
	var mixins:Mixins;
	var palette:ColorPalette;
	var spacing:Spacings;
	var zIndex:ZIndexes;

	// TODO: typography
	// TODO: direction
	// TODO: breakpoints
}

@:enum 
abstract CGColors(String) to String {
	var Primary = "#a53fa1"; //purple
	var Secondary = "#84BD55"; //Cagette green	
	var Third = "#E95219";	//orange

	var White = "#FFFFFF";

	var Bg1 = "#E5D3BF"; //light greyed-pink-purple
	var Bg2 = "#F8F4E5"; //same but lighter
	var Bg3 = "#F2EBD9"; //used for active category BG

	var Firstfont = "#404040";//dark grey
	var Secondfont = "#7F7F7F";//middle grey
}

typedef Spacings = {
	var unit:Int;
}

typedef Mixins = {
	var appBar:Object;
	var leftPanel:Object;
}

@:enum abstract PaletteType(String) from String to String {
	var Light = "light";
	var Dark = "dark";
}

typedef ColorPalette = {
	var type:PaletteType;
	var contrastThreshold:Int;
	var tonalOffset:Float;
	var getContrastText:haxe.Constraints.Function;
	var augmentColor:haxe.Constraints.Function;

	// TODO: use the real types
	var primary:Dynamic;
	var secondary:Dynamic;
	var error:Dynamic;
	var action:Dynamic;

	//TODO : this is a test at first for cagette
	var cgColors: CGColors;

	var divider:String;

	var background:{
		paper:String,
		// default:String
		// custom values
		dark:String,

		//TODO : this is a test at first for cagette
		cgBg01:CGColors,
		cgBg02:CGColors,
		cgBg03:CGColors,
	};

	var grey:{
		// TODO
	};

	var text:{
		primary:String,
		secondary:String,
		disabled:String,
		hint:String,
		// custom values
		inverted: String,
		cgFirstfont: CGColors,
		cgSecondfont: CGColors,
	};

	var common:{
		black:String,
		white:String
	};

	// custom values
	var indicator:IndicatorsPalette;
}

typedef IndicatorsPalette = {
	var green:String;
	var yellow:String;
	var orange:String;
	var red:String;
}

typedef ZIndexes = {
	var mobileStepper:Int;
	var appBar:Int;
	var drawer:Int;
	var modal:Int;
	var snackbar:Int;
	var tooltip:Int;
}
