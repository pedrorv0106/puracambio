require 'openssl'

class FundIpnController < ApplicationController
	skip_before_filter :verify_authenticity_token

	$cp_merchant_id = ENV['COINPAYMENTS_MERCHANT_ID']
  $cp_ipn_secret = ENV['COINPAYMENTS_IPN_SECRET']


  def create
	  Rails.logger.info "Received an Instant Payment Notification(IPN)"
		if !check_params
 	  	head :bad_request
		  render status: 400, nothing: true
			return
		end

    $hmac = request.headers["HMAC"]
    $merchant = params[:merchant]
    $ipn_mode = params[:ipn_mode]
    $ipn_type = params[:ipn_type]
    $address = params[:address]
    $txn_id = params[:txn_id]
    $status = params[:status]
    $id = params[:id]

		$status = $status.to_f

		if !verify_request
 	  	head :bad_request
		  render status: 400, nothing: true
			return
		end

		if $status >= 100 || $status == 2
		  # payment is complete or queued for nightly payout, success
		  on_txn_completed
		else
		  if $status < 0
			  # payment error, this is usually final but payments will sometimes be reopened if there was no exchange rate conversion or with seller consent
			else
			  # payment is pending, you can optionally add a note to the order page
			end
		end

		render nothing: true
	end


	private

	def check_params
		if !params[:address].present?
			return false
		end
		if !params[:txn_id].present?
			return false
		end
		if !params[:ipn_type].present?
			return false
		end
		if !params[:status].present?
			return false
		end

		return true
	end


	def verify_request
  	if $merchant != $cp_merchant_id
    	Rails.logger.error "No or incorrect Merchant ID passed"
	  	return false
  	end

    if $ipn_mode != "hmac"
    	Rails.logger.error "No or incorrect IPN Mode passed"
	  	return false
		end

		if $hmac == nil
			Rails.logger.error "No HMAC sent"
			return false
		end

		digest = OpenSSL::Digest.new('sha512')
    hash = OpenSSL::HMAC.hexdigest(digest, $cp_ipn_secret, request.body.read)
		if $hmac != hash
			Rails.logger.error "Incorrect HMAC sent"
			return false
		end

		if $txn_id.length == 0 || $address.length == 0
			return false
		end

		return true
	end


	def on_txn_completed
		if $ipn_type == 'withdrawal'
		  on_withdraw_completed
		else
			if $ipn_type == 'deposit'
				on_deposit_completed
			end
		end
	end


	def on_withdraw_completed
		wds = Withdraw.all
		if wds.length < 1
			return
		end
		wds = wds.where(txid: $id)
		if wds.length < 1
			return
		end
		wds = wds.where(fund_uid: $address)
		if wds.length < 1
			return
		end

		wds.each do |wd|
			wd.update_column :txid, $txn_id
			wd.succeed
      wd.save!
		end
	end

	def on_deposit_completed
		$currency = params[:currency]
		$currency = $currency.downcase!
		$amount = params[:amount]
		$confirms = params[:confirms]

		AMQPQueue.enqueue(:deposit_coin, txid: $txn_id, channel_key: "satoshi", address: $address, amount: $amount, confirms: $confirms, currency: $currency)
	end

end
