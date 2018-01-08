# RestClient logs using << which isn't supported by the Rails logger,
# so wrap it up with a little proxy object.
# Source: https://stackoverflow.com/a/15006502
RestClient.log = Object.new.tap do |proxy|
    def proxy.<<(message)
        Rails.logger.info message
    end
end
