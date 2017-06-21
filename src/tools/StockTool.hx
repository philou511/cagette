package tools;

/**
 * ...
 * @author fbarbut
 */
class StockTool
{

	/**
	 * Stock dispatching between groups.
	 * 
	 * i.e we got 10kg of potatoes to dispatch with 3 groups.
	 * I dont want to have 3,3333 kg for each group , but something like [3,3,4]
	 */
	public static function dispatch(stock:Int, groups:Int){
		
		var out = [];
		
		var modulo = stock % groups;
		
		stock -= modulo;
		
		var s = Math.round(stock / groups);
		
		for ( i in 0...groups) out.push(s);

		for (i in 0...modulo){
			out[i % out.length]++;
		}
		
		return out;
		
	}
	
}