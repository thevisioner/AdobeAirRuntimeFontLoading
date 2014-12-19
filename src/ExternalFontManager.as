package
{
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.text.Font;
	import flash.events.Event;
	import flash.errors.IOError;
	import flash.events.IOErrorEvent;
	
	import ru.etcs.utils.FontLoader;
	
	
	/**
	 *  The ExternalFontManager abstracts font converting and loading process.
	 */
	public class ExternalFontManager extends EventDispatcher
	{
		private static const NATIVE_FILES_PATH:String = "C:\\air-native";
		
		private var fontLoaderRequest:URLRequest;
		private var fontConverter:FontConverter;
		private var deleteTempFiles:Boolean;
		private var processRunning:Boolean;
		private var fontLoader:FontLoader;
		private var completeEvent:Event;
		
		private var _initialized:Boolean;
		private var _loadedFont:Font;
		
		
		public function ExternalFontManager()
		{
			super();
		}
		
		
		/**
		 *  Return loaded Font instance.
		 */
		public function get loadedFont():Font
		{
			return _loadedFont;
		}
		
		
		/**
		 *  Return initialized value.
		 */
		public function get initialized():Boolean
		{
			return _initialized;
		}
		
		/**
		 *  Initialize ExternalFontManager instance.
		 */
		public function initialize():void
		{
			if (_initialized) return;
			
			fontConverter = new FontConverter();
			fontConverter.addEventListener(Event.COMPLETE, fontConverterCompleteHandler, false, 0, true);
			fontConverter.initialize();
			
			fontLoader = new FontLoader();
			fontLoaderRequest = new URLRequest();
			fontLoader.addEventListener(Event.COMPLETE, fontLoaderCompleteHandler, false, 0, true);
			fontLoader.addEventListener(IOErrorEvent.IO_ERROR, fontLoaderIOErrorEvent, false, 0, true);
			fontLoader.addEventListener(IOErrorEvent.VERIFY_ERROR, fontLoaderVerifyErrorHandler, false, 0, true);
			
			installNativeProcessFiles();
		}
		
		
		/**
		 *  Dispose ExternalFontManager instance.
		 */
		public function dispose():void
		{
			if (_initialized)
			{
				fontConverter.dispose(true);
				fontConverter.removeEventListener(Event.COMPLETE, fontConverterCompleteHandler, false);
				fontConverter = null;
				
				fontLoader.close();
				fontLoader.removeEventListener(Event.COMPLETE, fontLoaderCompleteHandler, false);
				fontLoader.removeEventListener(IOErrorEvent.IO_ERROR, fontLoaderIOErrorEvent, false);
				fontLoader.removeEventListener(IOErrorEvent.VERIFY_ERROR, fontLoaderVerifyErrorHandler, false);
				
				fontLoaderRequest = null;
				completeEvent = null;
				fontLoader = null;
				
				_loadedFont = null;
				_initialized = false;
			}
		}
		
		
		/**
		 *  Load font face file to process it for usage in AIR runtime.
		 *
		 *  @font File Font face file, *.ttf, *.otf, *.ttc, or *.dfont
		 *  @deleteTempFiles Boolean If true, delete temporary font SWF file after loaded
		 */
		public function loadFont(font:File, deleteTempFiles:Boolean = true):void
		{
			if (!_initialized)
			{
				throw new Error("ExternalFontManager must be initialized before loading font.");
			}
			
			if (font.exists)
			{
				this.deleteTempFiles = deleteTempFiles;
				_loadedFont = null;
				
				if (processRunning)
				{
					fontConverter.stop();
					fontLoader.close();
				}
				else
				{
					processRunning = true;
				}
				
				fontConverter.processFont(font);
			}
			else
			{
				throw new IOError("The font file does not exist.");
			}
		}
		
		private function fontConverterCompleteHandler(event:Event):void
		{
			event.stopImmediatePropagation();
			
			fontLoaderRequest.url = fontConverter.fontLibraryPath;
			fontLoader.load(fontLoaderRequest);
		}
		
		
		private function fontLoaderCompleteHandler(event:Event):void
		{
			event.stopImmediatePropagation();
			
			// Preserve font instance
			_loadedFont = fontLoader.fonts[0];
			
			if (deleteTempFiles)
			{
				fontConverter.deleteTempFiles();
			}
			
			if (!completeEvent)
			{
				completeEvent = new Event(Event.COMPLETE, false, true);
			}
			
			processRunning = false;
			
			// Font is ready to use, dispatch complete event
			dispatchEvent(completeEvent);
		}
		
		
		private function fontLoaderIOErrorEvent(event:IOErrorEvent):void
		{
			event.stopImmediatePropagation();
			throw new Error("Some error occurred.");
		}
		
		private function fontLoaderVerifyErrorHandler(event:IOErrorEvent):void
		{
			event.stopImmediatePropagation();
			throw new Error("Some error occurred.");
		}
		
		
		/**
		 *  Prevent native process issue related to executing batch script with spaces in file path.
		 */
		private function installNativeProcessFiles():void
		{
			var source:File = File.applicationDirectory.resolvePath("native");
			var destination:File = new File(NATIVE_FILES_PATH);
			if (!destination.exists)
			{
				source.addEventListener(Event.COMPLETE, installNativeProcessFilesCompleteHandler, false, 0, false);
				source.copyToAsync(destination);
			}
			else
			{
				_initialized = true;
			}
		}
		
		private function installNativeProcessFilesCompleteHandler(event:Event):void
		{
			event.stopImmediatePropagation();
			
			var source:File = event.target as File;
			source.removeEventListener(Event.COMPLETE, installNativeProcessFilesCompleteHandler, false);
			source = null;
			
			_initialized = true;
		}
	}
}