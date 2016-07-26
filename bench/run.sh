sh build.sh

echo == Crystal Generate File
./bin_generate_file
echo == Crystal Load File
./bin_load_file
echo == Crystal Pack
./bin_pack
echo == Crystal Unpack
./bin_unpack

echo == Ruby Generate File
ruby generate_file.rb
echo == Ruby Load File
ruby load_file.rb
echo == Ruby Pack
ruby pack.rb
echo == Ruby Unpack
ruby unpack.rb


