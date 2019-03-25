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
import react.vendor.SimpleMap;
using Lambda;

class VendorPage extends react.ReactComponentOfProps<{vendorInfo: VendorInfos, catalogProducts: Array<ProductInfo>, nextDistributions: Array<DistributionInfos>}>{



	public function new(props){
		super(props);
	}

	override public function render(){

		var distributionMarkers: Array<MarkerInfo> = Lambda.array(Lambda.map(props.nextDistributions,function(distrib) return { key: Std.string(distrib.id), latitude: distrib.place.latitude, longitude: distrib.place.longitude, content: jsx('
			<div>
				<span>${distrib.id}</span><br />
				<a href=${"/group/" + distrib.groupId} target="_blank">Voir le groupe</a>
			</div>') } ));

		return jsx('
		<Grid container spacing={0} direction=${Row} justify=${Center} style=${{maxWidth:"1240px",marginLeft:"auto",marginRight:"auto"}}>
			<Grid item xs={12}>
				<div style=${{backgroundImage: 'url("${props.vendorInfo.images.banner}")', backgroundSize: "cover", backgroundRepeat: "no-repeat", backgroundPosition: "center", position: "relative", width: "100%", height: "300px"}} >TEST</div>
			 </Grid>
		<Grid item xs={12} style=${{textAlign:"center"}}>
			<Avatar style=${{width:"100px", height:"100px", marginLeft: "auto", marginRight: "auto", marginTop: "-50px"}} src=${props.vendorInfo.images.portrait} />
			<h1 style=${{fontStyle: "normal"}}>${props.vendorInfo.name}</h1>
			<Grid item md={12} xs={12} style=${{textAlign:"center"}}>
				<Typography component="p" style=${{fontSize:"1.3rem"}}>
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
			</Grid>
        </Grid>
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
		<Grid item xs={12} sm={4} style=${{height: "500px", overflowY: Scroll, overflowX: Hidden, marginTop: "50px"}}>
			<GridList cellHeight={350} cols={1}>
				${props.nextDistributions.map(function(distribution:DistributionInfos) {				
					return jsx('
					<GridListTile key=${distribution.id}>
						<Card style=${{height: "300px"}}>
							<CardActionArea>
								<CardContent style=${{height: "300px"}}>
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
							<CardActions style=${{ marginTop: "60px", padding:"0px" }}>
								<Button href=${"/group/" + distribution.groupId} size=${Large} color=${Primary}>
									Accéder à la vente
								</Button>
							</CardActions>
						</Card>
					</GridListTile>');})}
			</GridList>
		</Grid>
		<Grid item xs={12} sm={8} className="distributions-map" style=${{marginTop: "50px"}}>
			<SimpleMap markers=${distributionMarkers} />
        </Grid>
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