package form;
import Common;
/**
 * ...
 * @author fbarbut
 */
class TxpProduct extends sugoi.form.elements.StringInput
{

	var taxo = db.TxpProduct.manager.all();
	
	public function new(name, label, value, ?required=false){
		super(name, label, value, required);
		cssClass += " typeahead";
		
		
	}
	
	override function render(){
		
		var r = super.render();
		
		var taxoStr = "\"" + Lambda.map(taxo, function(x) return x.name).join("\",\"") + "\"";
		
		return r+'
		<input type="hidden" name="txpProduct" class="txpProduct" value="" />
		<div class="txpProduct"></div>
		
		<script>
		var substringMatcher = function(strs) {
		  return function findMatches(q, cb) {
			var matches = [];
			var substrRegex = new RegExp(q, "i");

			$.each(strs, function(i, str) {
			  if (substrRegex.test(str)) {
				matches.push(str);
			  }
			});

			cb(matches);
		  };
		};

		var products = ['+taxoStr+'];

		$(".typeahead").typeahead({hint: true, highlight: true, minLength: 2},
		{name: "products",source: substringMatcher(products)});
		
		$(".typeahead").bind("typeahead:select", function(ev, suggestion) {
			$("div.txpProduct").html(suggestion);
			$("input.txpProduct").val(suggestion);
		});
		
		</script>
		';
		
		
	}
	
}