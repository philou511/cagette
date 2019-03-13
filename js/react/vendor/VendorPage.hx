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
import mui.core.CardActions;
import mui.core.Grid;
import mui.core.GridList;
import mui.core.GridListTile;
import mui.core.Link;
using Lambda;

class VendorPage extends react.ReactComponentOfPropsAndState<{vendorId : Int},{}>{

	public function new(props){
		super(props);
		this.state = {};		
	}

	override public function render(){
		return jsx('<Grid container style=${{maxWidth:"1240px", marginLeft:"150px"}} spacing={8}>
		<Grid item xs={12}>
        	<img style=${{objectFit:"contain"}} src="https://www.bannerbatterien.com/upload/filecache/Banner-Batterien-Windrder2-web_bd5cb0f721881d106522f6b9cc8f5be6.jpg" alt="Vendor Banner"/>
        </Grid>
		<Avatar style=${{width:"100px",height:"100px"}} alt="Hello World!" src="https://i.kinja-img.com/gawker-media/image/upload/s--vSY-o42Q--/c_scale,f_auto,fl_progressive,q_80,w_800/ecq5rsk3n1nolujedskk.jpg" />
		<Typography component="h1" style=${{fontSize:"2rem"}}>
			La ferme du radis enragé
		</Typography>
		${CagetteTheme.getIcon("basket")}
		<Typography paragraph={true} style=${{fontSize:"1.5rem"}}>
			Fruits, confitures
		</Typography>
		${CagetteTheme.getIcon("map-marker")}
		<Typography paragraph={true} style=${{fontSize:"1.5rem"}}>
			Bordeaux (33000)
		</Typography>
		${CagetteTheme.getIcon("link")}
		<Typography paragraph={true} style=${{fontSize:"1.5rem"}}>
			 <a href="http://www.monsite.com">
        		www.monsite.com
      		</a>
		</Typography>
		<Button variant=${Contained} color=${Primary}>
        	Bio
      	</Button>
		<GridList cols={6}>
			<GridListTile key={1}>
				<img src="https://material-ui.com/static/images/grid-list/breakfast.jpg" />
			</GridListTile>
			<GridListTile key={2}>
				<img src="https://material-ui.com/static/images/grid-list/burgers.jpg" />
			</GridListTile>
			<GridListTile key={3}>
				<img src="https://material-ui.com/static/images/grid-list/camera.jpg" />
			</GridListTile>
			<GridListTile key={4}>
				<img src="https://material-ui.com/static/images/grid-list/morning.jpg" />
			</GridListTile>
			<GridListTile key={5}>
				<img src="https://material-ui.com/static/images/grid-list/hats.jpg" />
			</GridListTile>
			<GridListTile key={6}>
				<img src="https://material-ui.com/static/images/grid-list/vegetables.jpg" />
			</GridListTile>
      	</GridList>
		<GridList cols={1}>
			<GridListTile key={1}>
				<Card>
					<CardContent>
						<Typography>
						Tous les jeudis 12h - 14h
						LIEU
						Prochaine livraison jeudi 20 décembre
						Commandez jusqu\'au 17 décembre à 12h

						${CagetteTheme.getIcon("map-marker")} BORGO - CAMPUS DOM
						Ancienne route 20290 BORGO
						</Typography>
					</CardContent>
					<CardActions>
						<Button>Accéder à la vente</Button>
					</CardActions>
    			</Card>
			</GridListTile>
			<GridListTile key={2}>
				<Card>
					<CardContent>
						<Typography>
						PROCHAINE LIVRAISON
						LIEU
						Commandez jusqu\'au 17 décembre à 12h

						${CagetteTheme.getIcon("map-marker")} BORGO - CAMPUS DOM
						Ancienne route 20290 BORGO
						</Typography>
					</CardContent>
					<CardActions>
						<Button>Accéder à la vente</Button>
					</CardActions>
    			</Card>
			</GridListTile>
      	</GridList>
		</Grid>');
	}
}