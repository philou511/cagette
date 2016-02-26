package;
import Common;

/**
 * Tutorial widget 
 * @author fbarbut<francois.barbut@gmail.com>
 */
class Tuto
{

	var name:String;
	var step:Int;
	
	public function new(name:String,step:Int) 
	{
		this.name = name;
		this.step = step;
		//close previous popovers
		var p = App.j(".popover");
		
		//if (p.length > 0) {
			//trace("hide");
			//p
			//untyped p.on("hidden.bs.popover", function(?_) { trace("on hide"); init(); } );
			//untyped p.on("hide.bs.popover", function(?_) { trace("on hide"); init(); } );
			untyped p.popover('hide');
		//}else {
			//trace("new");
			//init();
		//}
		//untyped p.popover("hide");
		//haxe.Timer.delay(	init ,1000);
		init();
		
		
	}
	
	function init() {
		
		var tuto = Data.TUTOS.get(name);
		var s = tuto.steps[step];
		if (s == null) js.Browser.alert("Invalid Tutorial step : " + step + "@" + name);
		
		if (s.element == null) {
		
			//no element, make a modal window
			var m = App.j('#myModal');
			untyped m.modal('show');
			m.addClass("help");
			m.find(".modal-body").html(s.text); 
			m.find(".modal-header").html("<span class='glyphicon glyphicon-hand-right'></span> "+tuto.name);
			
			var bt = App.j("<a class='btn btn-default'><span class='glyphicon glyphicon-chevron-right'></span> OK</a>");
			bt.click(function(?_) {
				untyped m.modal('hide');
				new Tuto(name, step + 1);
			});
			m.find(".modal-footer").html(bt);
			
			m.find(".modal-dialog").removeClass("modal-lg"); //small window pls
			//m.find(".modal-footer").hide();
			
		}else {
			
			//prepare Bootstrap "popover"
			var x = App.j(s.element).attr("title", tuto.name);
			var text = "<p>"+s.text+"</p>";
			switch(s.action) {
				case TANext :
					text += "<p><a onClick=\"_.getTuto('"+name+"',"+(step+1)+")\" class='btn btn-default btn-sm'><span class='glyphicon glyphicon-chevron-right'></span> Suite</a></p>";
				default:
			}
			
			//configure and open popover
			untyped x.popover({container:"body",content:text,html:true}).popover('show');	
		}
	}
	
}