package react;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.LoginBox.LoginBoxProps;


/**
 * ...
 * @author fbarbut
 */
class RegisterBox extends react.ReactComponentOfProps<LoginBoxProps>
{

	public function new(props:Dynamic) 
	{
		super(props);
	}
	
	
	override public function render(){
		
		return jsx('
			
			<div>
				<form action="/user/login" method="post" className="form-horizontal">
					<div className="form-group">
						<label htmlFor="pass" className="col-sm-4 control-label">Nom : </label>
						<div className="col-sm-8">
							<input id="pass" type="password" name="pass" value="" className="form-control"/>					
						</div>					
					</div>
					<div className="form-group">
						<label htmlFor="pass" className="col-sm-4 control-label">Prénom : </label>
						<div className="col-sm-8">
							<input id="pass" type="password" name="pass" value="" className="form-control"/>					
						</div>					
					</div>
					<div className="form-group">
						<label htmlFor="email" className="col-sm-4 control-label">Email : </label>
						<div className="col-sm-8">
							<input id="email"  className="form-control"type="text" name="name" value=""  />			
						</div>
					</div>
					<div className="form-group">
						<label htmlFor="pass" className="col-sm-4 control-label">Mot de passe : </label>
						<div className="col-sm-8">
							<input id="pass" type="password" name="pass" value="" className="form-control"/>					
						</div>					
					</div>
					<p className="text-center">
						<input type="submit" value="Inscription" className="btn btn-primary btn-lg" />						
					</p>
				</form>
				<hr/>
			
				
				redirect : ${props.redirectUrl}
			</div>
			
			
			
		');
		
		
	}

	
}