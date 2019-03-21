package react.vendor;

import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import mui.core.Typography;
import react.mui.CagetteTheme;
import mui.core.Avatar;
import mui.core.Button;
import mui.core.Card;
import mui.core.CardContent;
import mui.core.CardActionArea;
import mui.core.CardActions;
import mui.core.Grid;
import mui.core.GridList;
import mui.core.GridListTile;
import mui.core.GridListTileBar;
import mui.core.Link;
import mui.core.ListSubheader;
using Lambda;

class VendorPage extends react.ReactComponentOfPropsAndState<{vendorInfo: VendorInfos, catalogProducts: Array<ProductInfo>, nextDistributions: Array<DistributionInfos>},{}>{

	public function new(props){
		super(props);
		this.state = {};
	}

	override public function render(){

		return jsx('<Grid container spacing={24} direction=${Column} alignContent=${Center} alignItems=${Center} justify=${Center} style=${{maxWidth:"1240px",marginLeft:"auto",marginRight:"auto"}}>
		<Grid item xs={12}>
        	<img style=${{objectFit:"contain"}} src=${props.vendorInfo.images.banner} alt="Vendor Banner"/>
        </Grid>
		<Avatar style=${{width:"100px",height:"100px",position:css.Position.Absolute,top:"50px"}} src=${props.vendorInfo.images.portrait} />
		<Typography component="h1" style=${{fontSize:"2rem"}}>
			${props.vendorInfo.name}
		</Typography>
		<Typography align=${Left} paragraph={true} style=${{fontSize:"1.5rem"}}>
			${CagetteTheme.getIcon("basket")} ${props.vendorInfo.profession}
		</Typography>
		<Typography paragraph={true} style=${{fontSize:"1.5rem"}}>
			${CagetteTheme.getIcon("map-marker")} ${props.vendorInfo.city} (${props.vendorInfo.zipCode})
		</Typography>
		<Typography paragraph={true} style=${{fontSize:"1.5rem"}}>
			${CagetteTheme.getIcon("link")}&nbsp;&nbsp;
			<a href=${props.vendorInfo.linkUrl} target="_blank">
        		${props.vendorInfo.linkText}
      		</a>
		</Typography>
		<Typography paragraph={true} style=${{fontSize:"1.5rem"}}>
			${props.vendorInfo.desc}
		</Typography>
		<GridList cols={4}>
			<GridListTile key="Subheader" cols={4} style=${{ height: 'auto' }}>
				<Typography paragraph={true} style=${{fontSize:"1.5rem"}}>
					<br />Quelques uns de nos produits <br />
				</Typography>
			</GridListTile>
			<GridListTile key={1}>
				<img src=${props.catalogProducts[0].image} />
				<GridListTileBar title=${props.catalogProducts[0].name} />
			</GridListTile>
			<GridListTile key={2}>
				<img src=${props.catalogProducts[1].image} />
				<GridListTileBar title=${props.catalogProducts[1].name} />
			</GridListTile>
			<GridListTile key={3}>
				<img src=${props.catalogProducts[2].image} />
				<GridListTileBar title=${props.catalogProducts[2].name} />
			</GridListTile>
			<GridListTile key={4}>
				<img src=${props.catalogProducts[3].image} />
				<GridListTileBar title=${props.catalogProducts[3].name} />
			</GridListTile>
      	</GridList>
		<GridList cellHeight={160} cols={2}>
			${props.nextDistributions.map(function(distribution:DistributionInfos) {
				return jsx('<Card style=${{height: "300px", maxWidth:"400px", margin:"30px"}}>
			<CardActionArea>
				<CardContent style=${{height: "200px"}}>
					<Typography gutterBottom component="p">
						Prochaine livraison : ${Formatting.hDate(Date.fromTime(distribution.distributionStartDate))}
					</Typography>
					<Typography component="p">
						${CagetteTheme.getIcon("map-marker")}  ${distribution.place.name}<br />
						${distribution.place.address1}<br />
						${distribution.place.address2}<br />
						${distribution.place.city}<br />
						${distribution.place.zipCode}<br />
					</Typography>
					<Typography component="p">
						Les commandes ouvrent le : ${Formatting.hDate(Date.fromTime(distribution.orderStartDate))}<br />
						Les commandes ferment le : ${Formatting.hDate(Date.fromTime(distribution.orderEndDate))}
					</Typography>
				</CardContent>
			</CardActionArea>
			<CardActions>
				<Button size=${Large} color=${Primary}>
				Accéder à la vente
				</Button>
      		</CardActions>
    	</Card>');})}
		</GridList>
		<Typography component="h1" style=${{fontSize:"2rem"}}>
			Vous pouvez également me retrouver ici: ${props.vendorInfo.offCagette}
		</Typography>
		<Typography paragraph={true} style=${{fontSize:"1.5rem"}}>
			Photos de notre exploitation
		</Typography>
		<GridList cols={4}>
			<GridListTile key={1}>
				<img src=${props.vendorInfo.images.farm1} />
			</GridListTile>
			<GridListTile key={2}>
				<img src=${props.vendorInfo.images.farm2} />
			</GridListTile>
			<GridListTile key={3}>
				<img src=${props.vendorInfo.images.farm3} />
			</GridListTile>
			<GridListTile key={4}>
				<img src=${props.vendorInfo.images.farm4} />
			</GridListTile>
		</GridList>
		<Typography paragraph={true} style=${{fontSize:"1.5rem"}}>
				<br />Catalogue complet des produits <br />
		</Typography>
		<GridList cellHeight={160} cols={4}>
			${props.catalogProducts.map(function(product:ProductInfo) {
				return jsx('<GridListTile key={product.image} cols={1}>
					<img src={product.image} alt={product.name} />
					<GridListTileBar title=${product.name} />
				</GridListTile>');
			} )}
		</GridList>
	</Grid>');
	}
}