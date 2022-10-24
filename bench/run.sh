sh build.sh

echo == Crystal Generate File Ser
./bin_generate_file_ser
echo == Crystal Load File Ser
./bin_load_file_ser
echo == Crystal Pack
./bin_pack
echo == Crystal Unpack
./bin_unpack
echo == Crystal Copy
./bin_copy

echo == Ruby Generate File
ruby generate_file.rb
echo == Ruby Load File
ruby load_file.rb
echo == Ruby Pack
ruby pack.rb
echo == Ruby Unpack
ruby unpack.rb


