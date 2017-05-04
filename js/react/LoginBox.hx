package react;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;

typedef LoginBoxProps = {
	redirectUrl:String,
}

typedef LoginBoxState = {
	email:String,
	password:String,
	error:String
}

/**
 * Login Box
 * @author fbarbut
 */
class LoginBox extends react.ReactComponentOfPropsAndState<LoginBoxProps,LoginBoxState>
{

	public function new(props:LoginBoxProps) 
	{
		if (props.redirectUrl == null) props.redirectUrl = "/";	
		super(props);		
		this.state = {email:"", password:"", error:null};
	}
	
	function setError(err:String){
		this.setState(cast {error:err});
	}
	
	override public function render(){
		
		return jsx('<div>
			<$Error error="${state.error}" />
			<form action="/user/login" method="post" className="form-horizontal">
				<div className="form-group">
					<label htmlFor="email" className="col-sm-4 control-label">Email : </label>
					<div className="col-sm-8">
						<input id="email"  className="form-control"type="text" name="email" value="${state.email}" required="1" onChange={onChange}/>			
					</div>
				</div>
				<div className="form-group">
					<label htmlFor="password" className="col-sm-4 control-label">Mot de passe : </label>
					<div className="col-sm-8">
						<input id="password" type="password" name="password" value="${state.password}" className="form-control" required="1" onChange={onChange}/>					
					</div>					
				</div>
				<p className="text-center">						
					<a onClick={submit} className="btn btn-primary btn-lg" ><span className="glyphicon glyphicon-chevron-right"></span> Se connecter</a>
					<br/>
					<br/>
					<a href="/user/forgottenPassword">Mot de passe oublié ?</a>
				</p>
			</form>
			<hr/>
			<p className="text-center">
				<b>Pas encore inscrit ? </b>
				<a onClick={registerBox} className="btn btn-default">Inscrivez-vous ici</a>
			</p>
		</div>');
	}
	
	/**
	 * @doc https://facebook.github.io/react/docs/forms.html
	 */
	function onChange(e:js.html.Event){
		e.preventDefault();
		
		var name :String = untyped e.target.name;
		var value :String = untyped /*(e.target.value == "") ? null :*/ e.target.value;
		
		switch(name){
			case "email" : state.email = value;
			case "password" : state.password = value;			
		}
		
		this.setState(this.state);
	}
	
	public function registerBox(){
		
		var body = js.Browser.document.querySelector('#myModal .modal-body');
		ReactDOM.unmountComponentAtNode( body );
		
		js.Browser.document.querySelector("#myModal .modal-title").innerHTML = "Inscription";
		
		
		ReactDOM.render(jsx('<$RegisterBox redirectUrl="${props.redirectUrl}" />'),  body );
	}
	
	public function submit(e:js.html.Event ){
		
		if (state.email == ""){
			setError("Veuillez saisir votre email");
			return;
		}
		if (state.password == ""){
			setError("Veuillez saisir votre mot de passe");
			return;
		}
		
		//lock button
		var el : js.html.Element = cast e.target;
		el.classList.add("disabled");
		
		var req = new haxe.Http("/api/user/login");
		req.addParameter("email", state.email);
		req.addParameter("password", state.password);
		req.addParameter("redirecturl", props.redirectUrl);
		
		req.onData = function(d){
			
			el.classList.remove("disabled");
			
			var d = haxe.Json.parse(d);
			if (Reflect.hasField(d, "error"))	setError(d.error.message);
			if (Reflect.hasField(d, "success")) js.Browser.window.location.href = props.redirectUrl;
		}
		
		req.request(true);
	}
	
}