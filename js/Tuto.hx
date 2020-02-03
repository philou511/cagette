package;
import js.Browser;
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
		App.instance.tutoModal();

		var s = tuto.steps[step];
		
		//close previous popovers
		// var p = App.jq(".popover");
		// untyped p.popover('hide');
		
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
			var modalElement = Browser.document.getElementById("myModal");
			var modal = new bootstrap.Modal(modalElement);
			modal.show();
			
			modalElement.classList.add("help");
			modalElement.querySelector('.modal-body').innerHTML = s.text;
			modalElement.querySelector('.modal-header').innerHTML = "<span class='glyphicon glyphicon-hand-right'></span> "+tuto.name;
			modalElement.querySelector('.modal-dialog').classList.remove("modal-lg");

			var confirmButtonIcon = Browser.document.createElement('i');
			confirmButtonIcon.classList.add("icon");
			confirmButtonIcon.classList.add("icon-chevron-right");
			
			var confirmButton = Browser.document.createElement('a');
			confirmButton.classList.add("btn");
			confirmButton.classList.add("btn-default");
			confirmButton.appendChild(confirmButtonIcon);
			confirmButton.appendChild(Browser.document.createTextNode(" " + t._("OK")));

			modalElement.querySelector(".modal-footer").append(confirmButton);
			
			confirmButton.onclick = function () {
				modal.hide();
				new Tuto(name, step + 1);
			}; 	
		} else {
			trace("LLLLLAAAAAA");
			//prepare Bootstrap "popover"
			// var x = App.jq(s.element).first().attr("title", tuto.name+" <div class='pull-right'>"+(step+1)+"/"+tuto.steps.length+"</div>");
			var x = Browser.document.querySelector(s.element);
			x.setAttribute("title", tuto.name+" <div class='pull-right'>"+(step+1)+"/"+tuto.steps.length+"</div>");
			
			var text = "<p>" + s.text + "</p>";
			var bt = null;

			//configure and open popover			
			var p = switch(s.placement) {
				case TPTop: "top";
				case TPBottom : "bottom";
				case TPLeft : "left";
				case TPRight : "right";
				default : null;
			}

			var popover = new bootstrap.Popover(x, { container: "body", content: text , placement: p });
			popover.show();

			switch(s.action) {
				case TANext :
					var nextIcon = Browser.document.createElement('i');
					nextIcon.classList.add("icon");
					nextIcon.classList.add("icon-chevron-right");
					var link = Browser.document.createElement('a');
					link.classList.add("btn");
					link.classList.add("btn-default");
					link.appendChild(nextIcon);
					link.appendChild(Browser.document.createTextNode(" " + t._("Next")));
					bt = Browser.document.createElement('p');
					bt.appendChild(link);

					bt.onclick = function () {
						new Tuto(name, step + 1);
						popover.hide();
						if (LAST_ELEMENT!=null) {
							x.classList.remove("highlight");
						}
					}
				default:
			}
			
			
			//add a footer
			var footer = Browser.document.createElement("div");
			footer.classList.add("footer");
			footer.innerHTML = "<div class='pull-left'></div><div class='pull-right'></div>";

			if (bt != null) footer.querySelector(".pull-right").append(bt);
			footer.querySelector(".pull-left").append(createCloseButton(t._('Stop')));
			
			x.addEventListener("show.bs.popover", function () {
				trace("AADED", Browser.document.querySelector(".popover .popover-content"));
				Browser.document.querySelector(".popover .popover-content").append(footer);
			}, false);

			
			Browser.document.querySelector(s.element).classList.add("highlight");
			LAST_ELEMENT = s.element;
		}
	}

	function createCloseButton(?text) {
		var icon = Browser.document.createElement("span");
		icon.classList.add("glyphicon");
		icon.classList.add("glyphicon-remove");

		var btn = Browser.document.createElement("a");
		btn.classList.add("btn");
		btn.classList.add("btn-default");
		btn.classList.add("btn");
		btn.appendChild(icon);
		btn.appendChild(Browser.document.createTextNode(text==null ? "" : text));

		return btn;
	}
}