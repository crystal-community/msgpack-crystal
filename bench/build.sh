crystal build generate_file_serializable.cr --release -o bin_generate_file_ser
crystal build load_file_serializable.cr --release -o bin_load_file_ser
crystal build pack.cr --release -o bin_pack
crystal build unpack.cr --release -o bin_unpack
crystal build pack_unpack.cr --release -o bin_pack_unpack
