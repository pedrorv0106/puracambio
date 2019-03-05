
class Blockchain < ActiveRecord::Base
 # has_many :currencies, foreign_key: :blockchain_key, primary_key: :key
 # has_many :wallets, foreign_key: :blockchain_key, primary_key: :key
  def process_blockchain(blocks_limit: 250, force: false)
    Rails.logger.info { "Blockchain: #{self}"}
     
    currency = 'tlcp'
    latest_block = CoinRPC[currency].eth_blockNumber
    Rails.logger.info { "Latest Block: #{latest_block}, #{latest_block.to_i(16)}"}
    if self.height >= latest_block.to_i(16) && !force
      Rails.logger.info { "Skip synchronization. No new blocks detected height: #{self.height}, latest_block: #{latest_block}" }
      return
    end
    from_block   = self.height || 0
    to_block     = [latest_block.to_i(16), from_block + blocks_limit].min

    (from_block..to_block).each do |block_id|
        next if CoinRPC[currency].nil?
        block_json = CoinRPC[currency].eth_getBlockByNumber("0x#{block_id.to_s(16)}", true)

        next if block_json.blank? || block_json[:transactions].blank?

        deposit_txids = build_deposits(block_json)
        
        deposit_txids.each do |txid|
          AMQPQueue.enqueue(:deposit_coin, txid: txid, channel_key: "travelcoin")
        end

        Rails.logger.info { "Finished processing in block number #{block_id}." }
    end
    self.update(height: to_block + 1)
  
  end
  def build_deposits(block_json)
  	deposit_txids = Array[]
  	c = Currency.find_by_code('tlcp')
  	block_json[:transactions].each do |block_txn|
    	if block_txn['to'] == c.smart_contract_address 
		  PaymentAddress.where('currency = ?', 4).each do |payment_address|
	      	if (block_txn['input'].hex > 0) && (block_txn['input'][0..9] == "0xa9059cbb") && (block_txn['input'].include? payment_address.address[2..-1])
	      		Rails.logger.info { "Blockchain Hash #{block_txn['hash']}" }
	      		deposit_txids.push(block_txn['hash'])
	      	end
	      end
	    end
    end
    return deposit_txids
  end
end