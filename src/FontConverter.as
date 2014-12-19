package
{
	import flash.events.EventDispatcher;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.NativeProcessExitEvent;
	import flash.desktop.NativeProcess;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.errors.IOError;
	import flash.events.Event;
	
	
	/**
	 *  The FontConverter use AIR capability to execute native processes on the
	 *  host operating system. With help of FontSWF utility of Flex SDK it converts
	 *  a single font face from a font file into a SWF file.
	 *
	 *  See "Using the fontswf utility" at
	 *  http://help.adobe.com/en_US/flex/using/WS2db454920e96a9e51e63e3d11c0bf69084-7f5f.html
	 *  #WS02f7d8d4857b16776fadeef71269f135e73-8000 for more specific information.
	 */
	public class FontConverter extends EventDispatcher
	{
		private static const FONTSWF_PATH:String = "C:\\air-native\\win\\bin\\fontswf.bat";
		private static const CMD_PATH:String = "C:\\Windows\\System32\\cmd.exe";
		
		private var nativeProcessStartupInfo:NativeProcessStartupInfo;
		private var nativeProcessArguments:Vector.<String>;
		private var nativeProcess:NativeProcess;
		private var deferredDispose:Boolean;
		private var completeEvent:Event;
		private var fontLibrary:File;
		
		private var _initialized:Boolean;
		
		
		public function FontConverter()
		{
			super();
			
			if (!NativeProcess.isSupported)
			{
				throw new Error("NativeProcess is not supported.");
			}
		}
		
		
		/**
		 *  Return font SWF file native path.
		 */
		public function get fontLibraryPath():String
		{
			return fontLibrary.nativePath + ".swf";
		}
		
		
		/**
		 *  Return initialized value.
		 */
		public function get initialized():Boolean
		{
			return _initialized;
		}
		
		
		/**
		 *  Initialize FontConverter instance.
		 */
		public function initialize():void
		{
			if (_initialized) return;
			
			nativeProcessArguments = new Vector.<String>(6, true);
			nativeProcessArguments[0] = "/c";
			nativeProcessArguments[1] = new File(FONTSWF_PATH).nativePath;
			nativeProcessArguments[2] = "-3";
			nativeProcessArguments[3] = "-o";
			// nativeProcessArguments[4] = SWF output file path;
			// nativeProcessArguments[5] = font input file path;
			
			nativeProcessStartupInfo = new NativeProcessStartupInfo();
			nativeProcessStartupInfo.executable = new File(CMD_PATH);
			nativeProcessStartupInfo.arguments = nativeProcessArguments;
			
			nativeProcess = new NativeProcess();
			nativeProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, outputDataHandler, false, 0, true);
			nativeProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, errorDataHandler, false, 0, true);
			nativeProcess.addEventListener(NativeProcessExitEvent.EXIT, exitHandler, false, 0, true);
			
			_initialized = true;
		}
		
		
		/**
		 *  Dispose FontConverter instance.
		 */
		public function dispose(deleteTempFiles:Boolean = false):void
		{
			if (nativeProcess.running)
			{
				deferredDispose = true;
				nativeProcess.exit(true);
			}
			else if (_initialized)
			{
				nativeProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, outputDataHandler, false);
				nativeProcess.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, errorDataHandler, false);
				nativeProcess.removeEventListener(NativeProcessExitEvent.EXIT, exitHandler, false);
				
				nativeProcessStartupInfo = null;
				nativeProcessArguments = null;
				nativeProcess = null;
				completeEvent = null;
				
				if (deleteTempFiles)
				{
					this.deleteTempFiles();
				}
				else
				{
					fontLibrary = null;
				}
				
				_initialized = false;
			}
		}
		
		
		/**
		 *  Delete temporary font swf file located at C:\Documents and settings\userName\Local Settings\Temp\
		 */
		public function deleteTempFiles():void
		{
			if (fontLibrary)
			{
				var tempDirectory:File = fontLibrary.parent;
				try
				{
					tempDirectory.deleteDirectory(true);
				} catch (error:Error) { }
				
				fontLibrary = null;
			}
		}
		
		
		/**
		 *  Start native process to convert a single font face from a font file into a SWF file.
		 *
		 *  @font File Font face file, *.ttf, *.otf, *.ttc, or *.dfont
		 */
		public function processFont(font:File):void
		{
			if (font.exists)
			{
				var libraryFileName:String = font.name.toLowerCase();
				var lastDotIndex:int = libraryFileName.lastIndexOf(".");
				if (lastDotIndex > -1) libraryFileName = libraryFileName.substring(0, lastDotIndex);
				fontLibrary = File.createTempDirectory().resolvePath(libraryFileName.toLowerCase());
				
				nativeProcessArguments[4] = fontLibrary.nativePath;
				nativeProcessArguments[5] = font.nativePath;
				
				nativeProcess.start(nativeProcessStartupInfo);
			}
			else
			{
				throw new IOError("The font file does not exist.");
			}
		}
		
		
		/**
		 *  Stop native process if running.
		 */
		public function stop():void
		{
			if (nativeProcess && nativeProcess.running)
			{
				try
				{
					nativeProcess.exit(true);
				} catch (error:Error) { }
				
				deleteTempFiles();
			}
		}
		
		
		private function outputDataHandler(event:ProgressEvent):void
		{
			event.stopImmediatePropagation();
			//trace("OUTPUT: " + nativeProcess.standardOutput.readUTFBytes(nativeProcess.standardOutput.bytesAvailable));
		}
		
		private function errorDataHandler(event:ProgressEvent):void
		{
			event.stopImmediatePropagation();
			//trace("ERROR: " + nativeProcess.standardOutput.readUTFBytes(nativeProcess.standardOutput.bytesAvailable));
		}
		
		private function exitHandler(event:NativeProcessExitEvent):void
		{
			event.stopImmediatePropagation();
			
			if (deferredDispose)
			{
				deferredDispose = false;
				dispose();
			}
			else
			{
				if (event.exitCode === 0)
				{
					if (!completeEvent)
					{
						completeEvent = new Event(Event.COMPLETE, false, true);
					}
					
					// Font SWF file is ready to load, dispatch complete event
					dispatchEvent(completeEvent);
				}
				else
				{
					throw new Error("Some error occurred. Process terminated.");
				}
			}
		}
	}
}