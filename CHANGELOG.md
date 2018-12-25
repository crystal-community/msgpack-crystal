## 0.13.1 (2018-12-21)
* **(breaking change)** Rewrite Unpacker logic, changed Token, Lexer and Unpacker
* **(breaking change)** Remove unpacker methods: from_msgpack64, to_msgpack64
* **(breaking change)** Remove Eof token (raises EofError instead)
* **(breaking change)** Rename unpacker method read_value_tokens to read_node
* **(breaking change)** Rename TokensUnpacker to NodeUnpacker
* **(breaking change)** Rename UnpackException to UnpackError
* **(breaking change)** MessagePack::Type have only one type Int64 for ints, and Float64 for floats
* Add more exception types for every case

## 0.12.1 (2018-12-14)
* **(breaking change)** Rename MessagePack::Unpacker to MessagePack::IOUnpacker
* Add MessagePack::TokensUnpacker
* Add unpacker method read_value_tokens, to read value as tokens array
* Optimize read Unions, without create temporary msgpack
* Fix #52, reading from stream when data types mismatch

## 0.11.1 (2018-11-27)
* fixed nilable types in NamedTuple, #49

## 0.11.0 (2018-11-26)
* fixed unpack nilable option in NamedTuple, #49
* refactor replace symbols with enums, thanks Fryguy, #47

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
