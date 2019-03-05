module Worker
  class SmsNotification

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      raise "TWILIO_NUMBER not set" if ENV['TWILIO_NUMBER'].blank?
      Rails.logger.info { "Phone number: #{Phonelib.parse(payload[:phone]).international}." }
      Rails.logger.info { "Phone number1: #{ENV["TWILIO_NUMBER"]}, #{ENV["TWILIO_SID"]}, #{ENV["TWILIO_TOKEN"]}." }
      twilio_client.api.account.messages.create(
        from: ENV["TWILIO_NUMBER"],
        to:   Phonelib.parse(payload[:phone]).international,
        body: payload[:message]
      )
    end

    def twilio_client
      Twilio::REST::Client.new ENV["TWILIO_SID"], ENV["TWILIO_TOKEN"]
    end

  end
end
