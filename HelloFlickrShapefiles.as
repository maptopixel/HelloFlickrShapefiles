package {
	import com.modestmaps.Map;
	import com.modestmaps.TweenMap;
	import com.modestmaps.events.MapEvent;
	import com.modestmaps.extras.MapControls;
	import com.modestmaps.extras.MapCopyright;
	import com.modestmaps.extras.ZoomSlider;
	import com.modestmaps.mapproviders.microsoft.MicrosoftHybridMapProvider;
	import com.modestmaps.overlays.PolygonMarker;
	import com.modestmaps.core.MapExtent;
	import com.modestmaps.geo.Location;
	import com.modestmaps.events.MarkerEvent;
	import com.modestmaps.overlays.PolygonClip;
	import com.modestmaps.extras.Distance;

	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;

	import flash.display.Sprite;
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.media.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;
	import flash.text.TextField;
	import flash.text.TextFieldType;

	import com.adobe.serialization.json.*;
	import com.adobe.serialization.json.JSON;

	import CrossMarker;

	[SWF(backgroundColor="#ffffff")];
	public class HelloFlickrShapefiles extends Sprite {
		public var map:Map;
		public var flickrID = "PUT_YOUR_OWN_FLICKR_ID_HERE";
		public var polygonClip:PolygonClip;
		public var numPolygonsTxt:TextField = new TextField();
		public var woeidTxt:TextField = new TextField();
		
		public var loadedPolygons:Array;
		public var polygonDetails:Array;

		public function HelloFlickrShapefiles() {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			map = new TweenMap(stage.stageWidth, stage.stageHeight, true, new MicrosoftHybridMapProvider());
			map.addEventListener(MouseEvent.DOUBLE_CLICK, map.onDoubleClick);
			addChild(map);

			map.addChild(new MapControls(map));
			map.addChild(new MapCopyright(map));

			var infoBox:Shape = new Shape();
			infoBox.graphics.beginFill(0xffffff);
			infoBox.graphics.drawRect(stage.stageWidth-305,stage.stageHeight-100, 300, 100);
			infoBox.graphics.endFill();
			infoBox.alpha = 0.5;
			map.addChild(infoBox);

			numPolygonsTxt.text = "Polygon information...";
			numPolygonsTxt.width = 299;
			numPolygonsTxt.x = stage.stageWidth-299;
			numPolygonsTxt.y = stage.stageHeight-99;
			map.addChild(numPolygonsTxt);
			
			woeidTxt.htmlText = "Woeid information...";
			woeidTxt.multiline = true;
			woeidTxt.width = 299;
			woeidTxt.x = stage.stageWidth-299;
			woeidTxt.y = stage.stageHeight-69;
			map.addChild(woeidTxt);
						
			var centre:Location = new Location(51.521134, -0.102654);
			map.setCenterZoom(centre, 14);

			// make sure the map fills the screen:
			stage.addEventListener(Event.RESIZE, onStageResize);
			map.addEventListener(MapEvent.STOP_PANNING, initFlickrShapeFiles);

			polygonClip = new PolygonClip(map);
			polygonClip.addEventListener(MarkerEvent.MARKER_ROLL_OVER, onMarkerRollOver);
			map.grid.addChild(polygonClip);
			
			initFlickrShapeFiles();
		}//constructor


		public function onStageResize(event:Event):void {
			map.setSize(stage.stageWidth, stage.stageHeight);
		}
		private function initFlickrShapeFiles(event:MapEvent=null):void {
			removeAllPolygons();
			generateFlickrBbox(22,map.getCenter());
		}
		private function onMarkerRollOver(event:MarkerEvent):void {
			var polygon:PolygonMarker = (event.marker as PolygonMarker);
			polygon.fillColor =0xffffff;
			polygon.redraw();
			var str:String = polygon.name;
			var results:Array = str.split("instance");
			trace(loadedPolygons[int(results[1])]);
			woeidTxt.htmlText = loadedPolygons[int(results[1])];
		}
		public function displayPolygon(woeid) {
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest();

			//call the flickr service with no callback function
			request.url="http://api.flickr.com/services/rest/?method=flickr.places.getInfo&api_key="+flickrID+"&woe_id="+woeid+"&format=json&nojsoncallback=1";
			loader.load(request);
			loader.addEventListener(Event.COMPLETE, decodeJSON);

			function decodeJSON(event:Event):void {
				var loader:URLLoader = URLLoader(event.target);
				//get the raw JSON data and cast to String
				var rawData:String = String(loader);
				var test:String = loader.data;
				// Decode the JSON string to an object
				var data:Object = JSON.decode(test);
				if (data.place.has_shapedata == 1) {
					var split:String = data.place.shapedata.polylines.polyline[0]._content;
					var points:Array = split.split(" ");

					var locations2:Array = new Array();
					for each (var point in points) {
						var tmp:Array = point.split(",");
						locations2.push( new Location(tmp[0],tmp[1]) );
					}
					var polygon:PolygonMarker = new PolygonMarker(map,locations2,true);
					polygon.mouseEnabled=true;
					polygon.fillColor =   Math.round(Math.random() * 0xFFFFFF);//random colour
					polygon.fillAlpha = 0.5;
					polygonClip.attachMarker(polygon, polygon.location);
					var str:String = polygon.name;
					var results:Array = str.split("instance");
					loadedPolygons[int(results[1])] = woeid + "<br>"+data.place.place_url;
				}//end if
			}
		}
		public function removeAllPolygons() {
			map.removeAllMarkers();
			map.removeMarker("1");
			this.polygonClip.removeAllMarkers();
		}
		public function offset(x,y,off_x,off_y) {
			return new Location(x + off_x,y + off_y);
		}
		////////////////////////////////////
		//The following is taken from:http://econym.org.uk/gmap/eshapes.htm
		public function EOffsetBearing(point,dist,bearing) {
			var latConv = Distance.approxDistance(point,(new Location(point.lat+0.1,point.lon)))*10;
			var lonConv = Distance.approxDistance(point,(new Location(point.lat,point.lon+0.1)))*10;

			var lat=dist * Math.cos(bearing * Math.PI/180)/latConv;
			var lon=dist * Math.sin(bearing * Math.PI/180)/lonConv;

			return new Location(point.lat + lat,point.lon + lon);
		}
		//////////////////////////////////

		public function generateFlickrBbox(place_type_id,currentCentre) {
			var centrePoint = new Location(currentCentre.lat,currentCentre.lon);
			var location1;
			var location2;

			switch (place_type_id) {
				case 22 :
					location1 = EOffsetBearing(currentCentre,1400,225);
					location2 = EOffsetBearing(currentCentre,1400,45);
					break;
				case 7 :
					location1 = EOffsetBearing(currentCentre,1500,225);
					location2 = EOffsetBearing(currentCentre,1500,45);
					break;
				case 8 :
					location1 = EOffsetBearing(currentCentre,1500,45);
					location2 = EOffsetBearing(currentCentre,1500,225);
					break;
				case 12 :
					location1 = EOffsetBearing(currentCentre,1500,45);
					location2 = EOffsetBearing(currentCentre,1500,225);
					break;
				case 29 :
					location1 = EOffsetBearing(currentCentre,1500,45);
					location2 = EOffsetBearing(currentCentre,1500,225);
					break;
					//default: result = 'unknown';
			}
			loadBoundariesByBbox(location1,location2);
		}//generate flickr box

		public function loadBoundariesByBbox(location1,location2) {
			var bbox = location1.lon+","+location1.lat+","+location2.lon+","+location2.lat;
			placeMarker(location1.lon,location1.lat);
			placeMarker(location2.lon,location2.lat);

			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest();
			//call the flickr service with no callback function
			request.url="http://api.flickr.com/services/rest/?method=flickr.places.placesForBoundingBox&api_key=" + flickrID + "&bbox="+bbox+"&place_type_id=22&format=json&nojsoncallback=1";
			loader.load(request);
			loader.addEventListener(Event.COMPLETE, decodeJSON);

			function decodeJSON(event:Event):void {
				var loader:URLLoader = URLLoader(event.target);
				//get the raw JSON data and cast to String
				var rawData:String = String(loader);
				var test:String = loader.data;
				// Decode the JSON string to an object
				var data:Object = JSON.decode(test);

				//output number of polygons
				numPolygonsTxt.text = "# of polys found: " + int(data.places.total);
				loadedPolygons = new Array();
				for (var i=0; i<data.places.total; i++) {
					displayPolygon(data.places.place[i].woeid);
				}
			}
		}//end load Boundaries Box
		private function placeMarker(lon,lat):void {
			var marker:CrossMarker = new CrossMarker();
			var loc:Location = new Location (lat, lon);
			map.putMarker( loc, marker);
		}
	}//class
}//package