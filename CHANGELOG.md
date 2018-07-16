## 0.10.0 (2018-07-16)
* Updated to crystal 0.25.0
* Added MessagePack::Serializable

## 0.8.0 (2018-03-04)
* Add getter/setter option to mappings
* Allow default value for hash
* Add emit_nulls option for mappings

## 0.7.1 (2017-05-08)
* Allow String load from String and from Binary

## 0.7.0 (2017-02-27)
* Fixed NamedTuple packing, unpacking
* Added method to_msgpack(io : IO)
* Fixed packing unions with nils

## 0.6.0 (2016-7-26)
* Added union support

## 0.5.0 (2016-6-16)
* Updated to crystal 0.18.0
* Added enum support
* Several bug fixes

## 0.4.0 (2016-3-5)
* Support for binary (@Thanks @maiha)
* Faster writes (Thanks @kostya)
* Faster reads (Thanks @asterite)
* Mapping (Thanks @kostya)
* Writers for tuples and symbols (@kostya)

## 0.3.1 (2016-01-22)
* Unpacker#has_next returns true if there are more items to be unpacked

## 0.1.0 (2015-10-18)

* **(breaking change)** MessagePack.pack now returns a slice (thanks @Xanders)
