crystal build generate_file_serializable.cr --release -o bin_generate_file_ser --no-debug
crystal build load_file_serializable.cr --release -o bin_load_file_ser --no-debug
crystal build pack.cr --release -o bin_pack --no-debug
crystal build unpack.cr --release -o bin_unpack --no-debug
crystal build pack_unpack.cr --release -o bin_pack_unpack --no-debug
crystal build copy.cr --release -o bin_copy --no-debug
