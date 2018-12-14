require "./spec_helper"
require "socket"

class SocketPerson
  MessagePack.mapping({
    name: {type: String},
    age:  {type: Int32, nilable: true},
  })

  def initialize(@name : String, @age : Int32? = nil)
  end
end

describe "read from socket" do
  it "unpacks form a socket" do
    TCPServer.open("localhost", 5000) do |server|
      TCPSocket.open("localhost", server.local_address.port) do |client|
        sock = server.accept

        packer = MessagePack::Packer.new(client)
        (1..3).each do |i|
          packer.write(i)
        end

        unpacker = MessagePack::IOUnpacker.new(sock)

        (1..3).each do |i|
          unpacker.read_value.should eq i
        end
      end
    end
  end

  it "unpack mapping from socket" do
    TCPServer.open("localhost", 5000) do |server|
      TCPSocket.open("localhost", server.local_address.port) do |client|
        sock = server.accept

        person = SocketPerson.new "Albert", 25
        client.write(person.to_msgpack)

        pull = MessagePack::IOUnpacker.new(sock)
        person2 = SocketPerson.new(pull)
        person2.name.should eq "Albert"
        person2.age.should eq 25
      end
    end
  end

  it "to_msgpack pack directly to socket, unpack mapping from socket" do
    TCPServer.open("localhost", 5000) do |server|
      TCPSocket.open("localhost", server.local_address.port) do |client|
        sock = server.accept

        person = SocketPerson.new "Albert", 25
        person.to_msgpack(client)

        pull = MessagePack::IOUnpacker.new(sock)
        person2 = SocketPerson.new(pull)
        person2.name.should eq "Albert"
        person2.age.should eq 25
      end
    end
  end
end
