module Worker
  class DepositCoin

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      sleep 0.5 # nothing result without sleep by query gettransaction api

      channel_key = payload[:channel_key]
      txid = payload[:txid]
      channel = DepositChannel.find_by_key(channel_key)
      if channel.currency_obj.code == 'tlcp'
        raw = CoinRPC['tlcp'].eth_getTransactionByHash(txid)
        raw.symbolize_keys!
        deposit_tlcp!(channel, txid, 1, raw)
      else
        # raw  = get_raw channel, txid
        # raw[:details].each_with_index do |detail, i|
        #   detail.symbolize_keys!
        #   deposit!(channel, txid, i, raw, detail)
        # end
				deposit_coinpayments!(channel, txid, 1, payload)
      end
    end

    def deposit_tlcp!(channel, txid, txout, raw)
      ActiveRecord::Base.transaction do
        return if PaymentTransaction::Normal.where(txid: txid, txout: txout).first

        if (raw[:input].hex > 0) && (raw[:input][0..9] == "0xa9059cbb")
          confirmations = CoinRPC['tlcp'].eth_blockNumber.to_i(16) - raw[:blockNumber].to_i(16)
          tx = PaymentTransaction::Normal.create! \
          txid: txid,
          txout: txout,
          address: "0x" + raw[:input][34..73],
          amount: (raw[:input][74..138].to_i(16) / 1e18).to_d,
          confirmations: confirmations,
          receive_at: Time.now.to_datetime,
          currency: channel.currency

          deposit = channel.kls.create! \
          payment_transaction_id: tx.id,
          txid: tx.txid,
          txout: tx.txout,
          amount: tx.amount,
          member: tx.member,
          account: tx.account,
          currency: tx.currency,
          confirmations: tx.confirmations

          deposit.submit!
        end
      end
    rescue
      Rails.logger.error "Failed to deposit: #{$!}"
      Rails.logger.error "txid: #{txid}, txout: #{txout}, detail: #{raw.inspect}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    def deposit!(channel, txid, txout, raw, detail)
      return if detail[:account] != "payment" || detail[:category] != "receive"

      ActiveRecord::Base.transaction do
        unless PaymentAddress.where(currency: channel.currency_obj.id, address: detail[:address]).first
          Rails.logger.info "Deposit address not found, skip. txid: #{txid}, txout: #{txout}, address: #{detail[:address]}, amount: #{detail[:amount]}"
          return
        end

        return if PaymentTransaction::Normal.where(txid: txid, txout: txout).first

        tx = PaymentTransaction::Normal.create! \
        txid: txid,
        txout: txout,
        address: detail[:address],
        amount: detail[:amount].to_s.to_d,
        confirmations: raw[:confirmations],
        receive_at: Time.at(raw[:timereceived]).to_datetime,
        currency: channel.currency

        deposit = channel.kls.create! \
        payment_transaction_id: tx.id,
        txid: tx.txid,
        txout: tx.txout,
        amount: tx.amount,
        member: tx.member,
        account: tx.account,
        currency: tx.currency,
        confirmations: tx.confirmations

        deposit.submit!
      end
    rescue
      Rails.logger.error "Failed to deposit: #{$!}"
      Rails.logger.error "txid: #{txid}, txout: #{txout}, detail: #{detail.inspect}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    def get_raw(channel, txid)
      channel.currency_obj.api.gettransaction(txid)
    end

    def get_raw_tlcp(txid)
      CoinRPC['tlcp'].eth_getTransactionByHash(txid)
    end

		def deposit_coinpayments!(channel, txid, txout, payload)
			address = payload[:address]
			amount = payload[:amount]
			currency = payload[:currency]
			confirms = payload[:confirms]

      ActiveRecord::Base.transaction do
        return if PaymentTransaction::Normal.where(txid: txid, txout: txout).first

        tx = PaymentTransaction::Normal.create! \
        txid: txid,
        txout: txout,
        address: address,
        amount: amount,
        confirmations: confirms,
        receive_at: Time.now.to_datetime,
        currency: currency

        deposit = channel.kls.create! \
        payment_transaction_id: tx.id,
        txid: tx.txid,
        txout: tx.txout,
        amount: tx.amount,
        member: tx.member,
        account: tx.account,
        currency: tx.currency,
        confirmations: tx.confirmations

        deposit.submit!
				tx.force_confirmed!
      end
    rescue
      Rails.logger.error "Failed to deposit: #{$!}"
      Rails.logger.error "txid: #{txid}, txout: #{txout}, detail: #{payload}"
      Rails.logger.error $!.backtrace.join("\n")
		end

  end
end
