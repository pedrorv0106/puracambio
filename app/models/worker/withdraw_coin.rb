module Worker
  class WithdrawCoin

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      Withdraw.transaction do
        withdraw = Withdraw.lock.find payload[:id]

        return unless withdraw.processing?

        withdraw.whodunnit('Worker::WithdrawCoin') do
          withdraw.call_rpc
          withdraw.save!
        end
      end

      Withdraw.transaction do
        withdraw = Withdraw.lock.find payload[:id]
	      c = Currency.find_by_code(withdraw.currency.to_s)
        # return unless withdraw.almost_done?
        if withdraw.currency == 'tlcp'
          #balance = CoinRPC[withdraw.currency].eth_getBalance(c.main_address, "latest")
          # Rails.logger.info "===Balance =#{balance}"
          #raise Account::BalanceError, 'Insufficient coins' if balance < withdraw.sum

         fee = [withdraw.fee.to_f || withdraw.channel.try(:fee) || 0.0005, 0.1].min
         res = CoinRPC[withdraw.currency].personal_unlockAccount(c.main_address, c.password, 3600)
         data = abi_encode \
          'transfer(address,uint256)',
          withdraw.fund_uid.downcase,
          '0x' + ((withdraw.amount.to_f * 1e18).to_i.to_s(16))

         txid = CoinRPC[withdraw.currency].eth_sendTransaction(from: c.main_address, to: c.smart_contract_address, value: "0x0", "gas":"0xd663", "gasPrice":"0x0",
         data: data)
         withdraw.whodunnit('Worker::WithdrawCoin') do
          withdraw.update_column :txid, txid

          # withdraw.succeed! will start another transaction, cause
          # Account after_commit callbacks not to fire
          withdraw.succeed
          withdraw.save!
        end
        else
#          balance = CoinRPC[withdraw.currency].getbalance.to_d
#          raise Account::BalanceError, 'Insufficient coins' if balance < withdraw.sum
#
#          fee = [withdraw.fee.to_f || withdraw.channel.try(:fee) || 0.0005, 0.1].min
#
#          CoinRPC[withdraw.currency].settxfee fee
#          txid = CoinRPC[withdraw.currency].sendtoaddress withdraw.fund_uid, withdraw.amount.to_f

#					Rails.logger.info "===TEMP address=#{withdraw.fund_uid}"
					options = { auto_confirm: 1 }
          r = Coinpayments.create_withdrawal(withdraw.amount.to_f, withdraw.currency, withdraw.fund_uid)
#          r = Coinpayments.create_withdrawal(withdraw.amount.to_f, 'ltct', withdraw.fund_uid, options)
					if r.kind_of?(Hash)
#						Rails.logger.info "===TEMP r=#{r}"
						txid = r.id
						withdraw.whodunnit('Worker::WithdrawCoin') do
  			      withdraw.update_column :txid, txid
      			  withdraw.save!
		      	end
					else
						Rails.logger.error "Failed to withdraw: #{r}"
						withdraw.whodunnit('Worker::WithdrawCoin') do
							withdraw.cancel
  	        	withdraw.save!
						end
					end
        end
      end
    end
    def abi_encode(method, *args)
      '0x' + args.each_with_object(Digest::SHA3.hexdigest(method, 256)[0...8]) do |arg, data|
        data.concat(arg.gsub(/\A0x/, '').rjust(64, '0'))
      end
    end
  end
end
