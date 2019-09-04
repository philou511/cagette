package;
import Common;

/**
 * Tutorial javascript widget 
 * @author fbarbut<francois.barbut@gmail.com>
 */
class Tuto
{
	var name:String;
	var step:Int;
	
	static var LAST_ELEMENT :String = null; //last hightlit element
	static var STOP_URL  = "/account?stopTuto=";
	
	public function new(name:String, step:Int){
		this.name = name;
		this.step = step;
		TutoDatas.get(name, init);
	}
	
	/**
	 * asyn init
	 * @param	tuto
	 */
	function init(tuto) 
	{

		var s = tuto.steps[step];
		
		//close previous popovers
		var p = App.jq(".popover");
		untyped p.popover('hide');
		
		var t = App.instance.t;
		if (t == null) trace("Gettext translator is null");
		
		if (s == null) {
			/**
			 * tutorial is finished : display a modal window
			 */
			var m = App.jq('#myModal');
			untyped m.modal('show');
			m.addClass("help");			
			m.find(".modal-header").html("<span class='glyphicon glyphicon-hand-right'></span> "+tuto.name);
			m.find(".modal-body").html("<span class='glyphicon glyphicon-ok'></span> "+t._("This tutorial is over.")); 
			var bt = App.jq("<a class='btn btn-default'><span class='glyphicon glyphicon-chevron-right'></span> "+t._("Come back to tutorials page")+"</a>");
			bt.click(function(?_) {
				untyped m.modal('hide');
				js.Browser.location.href = STOP_URL+name;
			});
			m.find(".modal-footer").append(bt);
			m.find(".modal-dialog").removeClass("modal-lg"); //small window pls
			
		}else if (s.element == null) {
		
			/**
			 * no element, make a modal window (usually its the first step of the tutorial)
			 */
			var m = App.jq('#myModal');
			untyped m.modal('show');
			m.addClass("help");
			m.find(".modal-body").html(s.text); 
			m.find(".modal-header").html("<span class='glyphicon glyphicon-hand-right'></span> "+tuto.name);
			
			var bt = App.jq("<a class='btn btn-default'><i class='icon icon-chevron-right'></i> "+t._("OK")+"</a>");
			bt.click(function(?_) {
				untyped m.modal('hide');
				new Tuto(name, step + 1);
			});
			m.find(".modal-footer").append(bt);
			m.find(".modal-dialog").removeClass("modal-lg"); //small window pls
			
		}else {
			
			//prepare Bootstrap "popover"
			var x = App.jq(s.element).first().attr("title", tuto.name+" <div class='pull-right'>"+(step+1)+"/"+tuto.steps.length+"</div>");
			var text = "<p>" + s.text + "</p>";
			var bt = null;
			switch(s.action) {
				case TANext :
					
					bt = App.jq("<p><a class='btn btn-default btn-sm'><i class='icon icon-chevron-right'></i> "+t._("Next")+"</a></p>");
					bt.click(function(?_) {
						//untyped m.modal('hide');
						new Tuto(name, step + 1);
						if(LAST_ELEMENT!=null) App.jq(s.element).removeClass("highlight");
					});
					
				default:
			}
			
			//configure and open popover			
			var p = switch(s.placement) {
				case TPTop: "top";
				case TPBottom : "bottom";
				case TPLeft : "left";
				case TPRight : "right";
				default : null;
			}
			var options = { container:"body", content:text, html:true , placement:p};
			untyped x.popover(options).popover('show');	
			
			
			//add a footer
			var footer = App.jq("<div class='footer'><div class='pull-left'></div><div class='pull-right'></div></div>");
			
			if (bt != null) footer.find(".pull-right").append(bt);
			footer.find(".pull-left").append(makeCloseButton(t._('Stop')));
			
			App.jq(".popover .popover-content").append(footer);
			
			//highlight
			App.jq(s.element).first().addClass("highlight");
			LAST_ELEMENT = s.element;
		}
	}
	
	/**
	 * Make a "close" bt
	 */
	function makeCloseButton(?text) {
		var bt = App.jq("<a class='btn btn-default btn-sm'><span class='glyphicon glyphicon-remove'></span> "+(text==null?"":text)+"</a>");
		bt.click(function(?_) {			
			js.Browser.location.href = STOP_URL+name;
		});
		return bt;
	}
	
}