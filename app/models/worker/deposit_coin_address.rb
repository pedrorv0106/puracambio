module Worker
  class DepositCoinAddress

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      payment_address = PaymentAddress.find payload[:payment_address_id]
      return if payment_address.address.present?

      currency = payload[:currency]
      if currency == 'tlcp'
       c = Currency.find_by_code(currency)
       address  = CoinRPC[currency].personal_newAccount(c.password)
      else
      # address  = CoinRPC[currency].getnewaddress("payment")
	  #		address = get_callback_address('ltct')
	    address = get_callback_address(currency)
      end

      if payment_address.update address: address
        ::Pusher["private-#{payment_address.account.member.sn}"].trigger_async('deposit_address', { type: 'create', attributes: payment_address.as_json})
      end
    end

    def get_callback_address(currency)
			  args = { currency: currency }
        r = Coinpayments.api_call(args)
#	      Rails.logger.info "#{r}"
	      return r.address
    end
  end
end
