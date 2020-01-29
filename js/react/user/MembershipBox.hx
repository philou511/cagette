package react.user;

import js.html.Console;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.Error;
import react.mui.CagetteTheme;
import mui.core.*;
import react.mui.Box;
import react.user.MembershipHistory;
import react.user.MemberShipForm;

typedef MembershipBoxState = {
    loading:Bool,
    error:String,
    userName:String,
    availableYears:Array<{name:String,id:Int}>,
    memberships:Array<{name:String,date:Date,id:Int}>,
    membershipFee:Int,
    distributions:Array<{name:String,id:Int}>,
    paymentTypes:Array<{id:String,name:String}>,
	
};

typedef MembershipBoxProps = {
    userId:Int,
    groupId:Int,
    callbackUrl:String,
};

class MembershipBox extends ReactComponentOfPropsAndState<MembershipBoxProps,MembershipBoxState> {

	public function new( props : MembershipBoxProps ) {
        super(props);
        state = cast {loading:true};
    }
      
    override function componentDidMount() {
		//load 
		utils.HttpUtil.fetch('/api/user/membership/${props.userId}/${props.groupId}', GET, null, JSON).then(
			function(data:Dynamic) {
                // Console.log(data);
                for ( m in (data.memberships:Array<Dynamic>)){
                    m.date = Date.fromString(m.date);
                }

                setState({
                    loading : false,
                    userName : data.userName,
                    paymentTypes : data.paymentTypes,
                    availableYears : data.availableYears,
                    memberships : data.memberships,
                    membershipFee : data.membershipFee,
                    distributions : data.distributions,

                });
            }
        ).catchError(
            err -> setState( {error:err} )
        );
    }

  	override public function render() {
        var content = null;
        if(state.loading){
            content = <div><CircularProgress /></div>;
        }else{
            content = 
                <Grid container>
                    <Box mb={4}>
                        <Typography variant={mui.core.typography.TypographyVariant.H5}>Adhésions de ${state.userName}</Typography>
                    </Box>

                    <Grid container spacing=${mui.core.grid.GridSpacing.Spacing_4}>
                        <Grid item xs={6}>
                            <MembershipHistory memberships={state.memberships} />
                        </Grid>
                        <Grid item xs={6}>
                            <MemberShipForm
                                userId=${props.userId}
                                groupId=${props.groupId}
                                availableYears=${state.availableYears}
                                paymentTypes=${state.paymentTypes} />
                        </Grid>
                    </Grid>
                </Grid>
            ;
        }

        return jsx('<div>
            <Error error=${state.error}/>
            $content
        </div>');
    }
    
    function handleChange(){

    }
      
    function deleteMembership(year:Int){
        
    }
  
}