package { 
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.BevelFilter;  
	
	class CrossMarker extends Sprite {
		   
		private var _title : String;
		
		public function CrossMarker() {
				
			buttonMode = true;
			mouseChildren = false;
			tabEnabled = false;            
			//cacheAsBitmap = true;
			mouseEnabled = true;
			
			var hairThickness:int = 4;
			var hairLength:int = 24;
			graphics.beginFill(0x990000);

			//vertical line
			graphics.drawRect(0,-(hairLength/2)-(hairThickness/2),hairThickness,hairLength);
			//horizontal line
			graphics.drawRect(-(hairLength/2)+(hairThickness/2),-hairThickness,hairLength,hairThickness);
			graphics.endFill();
			addEventListener( MouseEvent.MOUSE_OVER, mouseOver );
		}
				
		public function get title () : String {
			return _title;
		}
		
		public function set title (s:String) : void {
			_title = s;
		}
				
		protected function mouseOver(e:MouseEvent) : void {
			parent.swapChildrenAt(parent.getChildIndex(this), parent.numChildren - 1);
		}
		
		override public function toString() : String {
			return '[CrossMarker] ' + title;
		}
	}//end class
}//end package