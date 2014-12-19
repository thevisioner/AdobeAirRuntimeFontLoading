package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.events.Event;
	import flash.text.Font;
	import flash.net.FileFilter;
	import flash.filesystem.File;
	import flash.text.TextFieldAutoSize;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	
	import com.bit101.components.PushButton;
	import com.bit101.components.Label;
	
	
	/**
	 *  Document class of application that is capable of loading external font face file to process it and use as Font instance in AIR runtime.
	 */
	public class ActionScriptRuntimeFontLoading extends Sprite
	{
		private static const SAMPLE_TEXT:String = "Grumpy wizards make toxic brew for the evil Queen and Jack.";
		
		private var textField:TextField;
		private var textFormat:TextFormat;
		
		private var fontFile:File;
		private var fontFileFilter:FileFilter;
		private var externalFontManager:ExternalFontManager;
		
		private var browseButton:PushButton;
		private var fontNameLabel:Label;
		
		
		public function ActionScriptRuntimeFontLoading()
		{
			super();
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler, false, 0, true);
		}
		
		private function addedToStageHandler(event:Event):void
		{
			event.stopImmediatePropagation();
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler, false);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			initialize();
		}
		
		
		private function initialize():void
		{
			browseButton = new PushButton(this, 20, 20, "Browse local font face", browseFileHandler);
			browseButton.width = 160;
			
			fontNameLabel = new Label(this, 200, 20, "- Output -");
			
			textField = new TextField();
			textField.autoSize = TextFieldAutoSize.LEFT;
			textField.embedFonts = true;
			textField.x = 20;
			textField.y = 50;
			addChild(textField);
			
			textFormat = new TextFormat(null, 25);
			
			fontFile = File.applicationDirectory.resolvePath("assets/fonts/");
			fontFile.addEventListener(Event.SELECT, fileSelectHandler, false, 0, true);
			fontFileFilter = new FileFilter("Font file", "*.ttf;*.otf");
			
			externalFontManager = new ExternalFontManager();
			externalFontManager.addEventListener(Event.COMPLETE, externalFontManagerCompleteHandler, false, 0, true);
			externalFontManager.initialize();
			
			stage.nativeWindow.addEventListener(Event.CLOSING, windowClosingHandler, false, 0, true);
		}
		
		
		private function windowClosingHandler(event:Event):void
		{
			event.stopImmediatePropagation();
			
			if (externalFontManager)
			{
				externalFontManager.dispose();
				externalFontManager = null;
			}
		}
		
		
		/**
		 *  Browse button click handler.
		 */
		private function browseFileHandler(event:Event):void
		{
			event.stopImmediatePropagation();
			fontFile.browseForOpen("Select font face", [fontFileFilter]);
		}
		
		/**
		 *  Font face file select handler.
		 */
		private function fileSelectHandler(event:Event):void
		{
			event.stopImmediatePropagation();
			externalFontManager.loadFont(event.target as File);
		}
		
		
		/**
		 *  ExternalFontManager complete event handler. Font is ready to use.
		 */
		private function externalFontManagerCompleteHandler(event:Event):void
		{
			event.stopImmediatePropagation();
			
			var loadedFont:Font = externalFontManager.loadedFont;
			fontNameLabel.text = "Font: " + loadedFont.fontName;
			
			textFormat.font = loadedFont.fontName;
			textField.text = SAMPLE_TEXT;
			textField.setTextFormat(textFormat, 0, textField.length - 1);
		}
	}
}