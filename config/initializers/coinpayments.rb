Coinpayments.configure do |config|
  config.merchant_id     = ENV['COINPAYMENTS_MERCHANT_ID']
  config.public_api_key  = ENV['COINPAYMENTS_PUBLIC_API_KEY']
  config.private_api_key = ENV['COINPAYMENTS_PRIVATE_API_KEY']
end
