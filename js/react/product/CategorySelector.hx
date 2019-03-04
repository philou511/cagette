package react.product;

import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import mui.core.Dialog;
import mui.core.DialogTitle;
import mui.core.Typography;
import mui.core.List;
import mui.core.ListItem;
import mui.core.ListItemText;
import react.mui.CagetteTheme;
import mui.core.ListItemIcon;
using Lambda;

class CategorySelector extends react.ReactComponentOfState<{categories : Array<CategoryInfo>}>{

	public function new(){
		super();
		this.state = {categories:[]};		
	}

	override public function render(){
		//faire des Item comme là ? https://material-ui.com/demos/dialogs/
		return jsx('
			<Dialog onClose={onClose} open={true} >
				<Typography component="h2" style=${{fontSize:"1.3rem",padding:12}}>Sélectionnez une catégorie</Typography>
				<SelectionPanel categories={this.state.categories} />
        	</Dialog>');
	}

	function onClose(e:js.html.Event,reason:mui.core.modal.ModalCloseReason){

	}	

	function close(e){
        onClose(e,mui.core.modal.ModalCloseReason.BackdropClick);
    }

	override function componentDidMount() {

		//Load categories from API
		var initRequest = utils.HttpUtil.fetch("/api/product/categories", GET, null, JSON).then(
			function(data:Dynamic) {
				this.setState({categories:data});
				this.render();
			}		

		).catchError(
			function(error) {
				throw error;
			}
		);
	}	

}

typedef SelectionPanelProps = {
	categories : Array<CategoryInfo>
}

typedef SelectionPanelState = {
	category1Id:Int,
	category2Id:Int,
	category3Id:Int
}

class SelectionPanel extends react.ReactComponentOfPropsAndState<SelectionPanelProps,SelectionPanelState>{

	public function new(props) 
	{
		super(props);
		this.state = {
			category1Id:0,
			category2Id:0,
			category3Id:0
		};
	}

	function getPath() {
        var path = "";
        var category1Id = this.state.category1Id;
        var category2Id = this.state.category2Id;
        var category3Id = this.state.category3Id;

        if (category1Id != 0) {
            path = this.getLevelCategories(1, 0, 0).filter(function(data) return data.id == category1Id )[0].name;
        }

        if (category2Id != 0) {
            path += " / " + this.getLevelCategories(2, category1Id, 0).filter(function(data) return data.id == category2Id )[0].name;
        }

        if (category3Id != 0) {
            path += " / " + this.getLevelCategories(3, category1Id, category2Id).filter(function(data) return data.id == category3Id )[0].name;
        }

        return path;
    }

        
	/**
		Click on a category on any level
	**/
	function handleClick(id:Int) {
		//trace(id);
		if (this.state.category1Id==0) {
			this.setState({ category1Id: id });              
		} else if (this.state.category2Id==0) {
			this.setState({ category2Id: id });
		} else if (this.state.category3Id==0) {
			this.setState({ category3Id: id });
		}

	}

	function getProductCategories() {

		var productCategories = [];
		var category1Id = this.state.category1Id;
		var category2Id = this.state.category2Id;
		
		//Level 1
		if (category1Id == 0) {
			productCategories = this.getLevelCategories(1, 0, 0);
		} 
		//Level 2          
		else if (category2Id == 0) {
			productCategories = this.getLevelCategories(2, category1Id, 0);
		}
		//Level 3
		else {            
			productCategories = this.getLevelCategories(3, category1Id, category2Id);
		}

		return productCategories;

	}

	function getLevelCategories(level:Int, category1Id:Int, category2Id:Int) {
		if (level == 1) {
			return this.props.categories;
		}
		else if  (level == 2) {
			return this.props.categories.filter(function(data) return data.id == category1Id )[0].subcategories;
		}
		else {

			var categories2 = this.props.categories.filter(function(data) return data.id == category1Id )[0].subcategories;
			return categories2.filter(function(data) return data.id == category2Id )[0].subcategories;
		}
	}

	override function render() {

		var productCategories = this.getProductCategories().map(function (item){
			var onClick = function(){
				handleClick(item.id);
			}; 
             
			return jsx('
			 <ListItem button onClick=$onClick key=${item.id}>
                <ListItemText primary=${item.name} />
              </ListItem>
			');
		});

		

		if(state.category1Id!=0){
			productCategories.push(
				jsx('
				<ListItem button onClick=$goBack key={0} style=${{backgroundColor:CGColors.Bg1}}>
					<ListItemIcon>
							${CagetteTheme.getIcon("chevron-left")}
					</ListItemIcon>
					<ListItemText primary="Retour" />
				</ListItem>
				')
			);

		}
		
		return jsx(' 
		<div>
			<div style=${{color:CGColors.Secondfont,padding:12,fontWeight:"bold"}}>${getPath()}</div>				   
			<List>
				$productCategories
			</List>                              
		</div>');
	
	}

	function goBack(_){
			
		if(state.category3Id!=0) {
			this.setState({category3Id:0});
		} else if (state.category2Id!=0){
			this.setState({category2Id:0});
		} else {
			this.setState({category1Id:0});
		}
	}	
}	

