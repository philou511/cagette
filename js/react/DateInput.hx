package react;
import react.ReactComponent;
import react.ReactMacro.jsx;

/**
 * Date picker using moment.js and http://eonasdan.github.io/bootstrap-datetimepicker/
 */
class DateInput extends react.ReactComponentOfPropsAndState<{date:Date,divId:String},{date:Date}>
{
	
	

	public function new(props:{date:Date,divId:String}) 
	{
		
		props.divId = "datePicker"+Std.random(9999999);
		super(props);
		
		App.j(function () {
			var dt = untyped App.j("#"+props.divId).datetimepicker(
				{
					locale:'fr',
					format:'LLLL',
					defaultDate:moment("2017-03-01 00:00:00", "YYYY-MM-DD HH:mm:ss")
				}
			);
			
			dt.on('dp.change',function(e){
				var d = App.j("#"+props.divId).data('DateTimePicker').date();//moment.js obj				
				this.setState({date:Date.fromString( d.format('YYYY-MM-DD HH:mm:ss') )} );
				trace(this.state);
			});
		});
	}
	
	
	override public function render(){
		
		return jsx('
		<div className="input-group col-md-3 datepinput" id="${props.divId}">
			<span className="input-group-addon">
				<span className="glyphicon glyphicon-calendar"></span>
			</span><input type="text" className="form-control" />
		</div>');
	}
	
}