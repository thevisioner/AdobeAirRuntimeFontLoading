Adobe Air runtime font loading
==============================

This project provides an experimental implementation of runtime font loading in Adobe Air application. Current implementation is based on FontSWF utility of Flex SDK. Font face file is converted to SWF file that is loaded as raw bytes, and then registered in Flash runtime and accessible as Font class instance.

- More information about fontswf: http://help.adobe.com/en_US/flex/using/WS2db454920e96a9e51e63e3d11c0bf69084-7f5f.html#WS02f7d8d4857b16776fadeef71269f135e73-8000


TODO
====

The project should be considered experimental at this point and still has many features that need to be implemented. In descending priority order, I would say that the next things that need to be done are:

- resolve issue related to spaces in batch script path when executing it from native process.
- implement support for Mac OS (native process to convert font face file into SWF).
