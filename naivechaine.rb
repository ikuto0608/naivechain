require 'socket'
require 'digest'
require 'json'

class Node
  def initialize(port, other_node_ports = [])
    @blockchain = [get_genesis_block]

    @clients = []
    other_node_ports.each do |other_node_port|
      client = TCPSocket.open('localhost', other_node_port)
      Thread.start do
        listen_message(client)
      end

      @clients << client
    end

    @server = TCPServer.open('localhost', port)
    init_connection

    mine_with_loop
  end

  def blockchain
    @blockchain
  end

  private
    def init_connection
      Thread.start do
        loop do
          Thread.start(@server.accept) do |client|
            @clients << client
            listen_message(client)
          end
        end
      end
    end

    def broadcast
      @clients.map {|client| client.puts(@blockchain.to_json) }
    end

    def listen_message(client)
      loop do
        other_blockchain = JSON.parse(client.gets)
        verify(other_blockchain)
      end
    end

    def mine_with_loop
      Thread.start do
        loop { mine; sleep(Random.rand(10)) }
      end
    end

    def mine
      @blockchain << generate_next_block(@blockchain.last)
      broadcast
    end

    def verify(blockchain)
      replace_chain(blockchain) if is_valid_chain(blockchain)
    end

    def is_valid_chain(blockchain)
      if blockchain[0] != get_genesis_block
        return false
      end
      temp_blocks = [blockchain[0]]
      blockchain[1..-1].each_with_index do |block, index|
        if is_valid_new_block(block, temp_blocks[index])
          temp_blocks << block
        else
          return false
        end
      end

      true
    end

    def generate_next_block(block_data)
      previous_block = @blockchain.last
      next_index = previous_block["index"] + 1
      next_timestamp = Time.now.to_i
      next_data = "Smart contract" + next_index.to_s
      next_hash = calculate_hash(
        next_index,
        previous_block["hash"],
        next_timestamp,
        next_data
      )

      {
        "index" => next_index,
        "previous_hash" => previous_block["hash"],
        "timestamp" => next_timestamp,
        "data" => next_data,
        "hash" => next_hash
      }
    end

    def calculate_hash_for_block(block)
      calculate_hash(block["index"], block["previous_hash"], block["timestamp"], block["data"])
    end

    def calculate_hash(index, previous_hash, timestamp, data)
      Digest::SHA256.base64digest(index.to_s + previous_hash.to_s + timestamp.to_s + data.to_s).to_s
    end

    def add_block(new_block)
      @blockchain << new_block if is_valid_new_block(new_block, @blockchain.last)
    end

    def is_valid_new_block(new_block, previous_block)
      if previous_block["index"] + 1 != new_block["index"]
        return false
      elsif previous_block["hash"] != new_block["previous_hash"]
        return false
      elsif calculate_hash_for_block(new_block) != new_block["hash"]
        return false
      end

      true
    end

    def replace_chain(new_blocks)
      @blockchain = new_blocks if is_valid_chain(new_blocks) && new_blocks.count > @blockchain.count
    end

    def get_genesis_block
      {
        "index" => 0,
        "previous_hash" => "0",
        "timestamp" => 1465154705,
        "data" => "my genesis block!!",
        "hash" => "816534932c2b7154836da6afc367695e6337db8a921823784c14378abed4f7d7"
      }
    end
end
