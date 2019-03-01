package react.product;

import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
using Lambda;



class CategorySelector extends react.ReactComponent{

	var categories : Array<CategoryInfo>;

	public function new(){
		super();
		categories = [];
	}

	override public function render(){
		return jsx('<div>
            <h3>Sélection de catégories</h3>
            <SelectionPanel categories={this.props.categories} />
        </div>');
	}	


	override function componentDidMount() {

		//Load categories from API
		var initRequest = utils.HttpUtil.fetch("/api/product/categories", GET, null, JSON).then(
			function(data:Dynamic) {
				categories = data;
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

	/* getPath() {
          let path = "";
          const category1Id = this.state.category1Id;
          const category2Id = this.state.category2Id;
          const category3Id = this.state.category3Id;

          if (category1Id != 0) {
            path = this.getLevelCategories(1, 0, 0).filter(function(data){ return data.id == category1Id })[0].name;
          }

          if (category2Id != 0) {
            path += " / " + this.getLevelCategories(2, category1Id, 0).filter(function(data){ return data.id == category2Id })[0].name;
          }

          if (category3Id != 0) {
            path += " / " + this.getLevelCategories(3, category1Id, category2Id).filter(function(data){ return data.id == category3Id })[0].name;
          }

          return path;
        }

        

        */

        function handleClick(id:Int) {
          
          if (this.state.category1Id!=0) {
            this.setState({ category1Id: id });              
          }
          else if (this.state.category2Id!=0) {
            this.setState({ category2Id: id });
          }
          else if (this.state.category3Id!=0) {
            this.setState({ category3Id: id });
          }

        }

		function getProductCategories() {

			var productCategories;
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
			  //<BreadCrumbs path={this.getPath()} />  

			  

			var productCategories = this.getProductCategories().map(function (item){
				var onClick = function(){
					handleClick(item.id);
				}; 
				return jsx('<ProductCategory key=${item.id} name=${item.name} onClick=$onClick/>');
			});

			return jsx(' 
			<div>				   
				<div>
					<div>
						{productCategories}
					</div>                              
				</div>
			</div>');
        
      	}



}	


class ProductCategory extends react.ReactComponentOfProps<{onClick:Void->Void,name:String}>{

	public function new(props) 
	{
		super(props);	
	}

	override function render(){
		return jsx('
          <button onClick=${props.onClick}>
            ${props.name}
          </button>
        ');
	}

}