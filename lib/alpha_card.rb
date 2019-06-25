# frozen_string_literal: true

# typed: true

require 'yaml'
require 'net/http'
require 'uri'
require 'rack/utils'
require 'openssl'

# Version
require 'alpha_card/version'

require 'alpha_card/account'
require 'alpha_card/attribute'
require 'alpha_card/resource'
require 'alpha_card/response'
require 'alpha_card/transaction'

# Errors
require 'alpha_card/errors/api_connection_error'
require 'alpha_card/errors/invalid_attribute_value'
require 'alpha_card/errors/invalid_attribute_format'
require 'alpha_card/errors/invalid_attribute_type'
require 'alpha_card/errors/validation_error'

# Alpha Card Resources
require 'alpha_card/resources/billing'
require 'alpha_card/resources/shipping'
require 'alpha_card/resources/order'

# Alpha Card Transactions
require 'alpha_card/transactions/capture'
require 'alpha_card/transactions/void'
require 'alpha_card/transactions/refund'
require 'alpha_card/transactions/sale'
require 'alpha_card/transactions/update'
require 'alpha_card/transactions/auth'
require 'alpha_card/transactions/credit'
require 'alpha_card/transactions/validate'

##
# AlphaCard is a library for processing payments with Alpha Card Services, Inc.
module AlphaCard
  ##
  # Alpha Card Gateway DirectPost API URL
  @api_base = 'https://secure.alphacardgateway.com/api/transact.php'

  ##
  # Global Payment Systems (NDC) Credit Card Authorization Codes
  #
  # @see http://floristwiki.ftdi.com/images/c/ce/Appendix_A_-_Credit_Card_Authorization_Codes.pdf Credit Card Authorization Codes
  CREDIT_CARD_CODES = YAML.load_file(File.expand_path('alpha_card/data/credit_card_codes.yml', __dir__))

  class << self
    # @return [String] Alpha Card Gateway DirectPost API URL.
    attr_accessor :api_base

    ##
    # Send the POST request to the AlphaCard Gateway from the
    # specified account. Request must contains params - Alpha Card
    # transaction variables.
    #
    # @param params [Hash]
    #   hash with Alpha Card transaction variables and it's values
    #
    # @param credentials [Hash]
    #   Alpha Card merchant account credentials
    #
    # @return [AlphaCard::Response]
    #   Response from Alpha Card Gateway.
    #
    # @raise [APIConnectionError] HTTP request error
    #
    # @example
    #   response = AlphaCard.request(
    #     {
    #       cexp: '0720',
    #       ccnumber: '4111111111111111',
    #       amount: '10.00'
    #     },
    #     {
    #       username: 'demo',
    #       password: 'password'
    #     }
    #   )
    #
    #   #=> #<AlphaCard::Response:0x1a0fda8 @data={"response"=>"1",
    #       "responsetext"=>"SUCCESS", "authcode"=>"123", "transactionid"=>"123",
    #       "avsresponse"=>"", "cvvresponse"=>"N", "orderid"=>"", "type"=>"",
    #       "response_code"=>"100"}>
    #
    def request(params = {}, credentials = Account.credentials)
      unless Account.valid_credentials?(credentials)
        raise ArgumentError, 'You must pass a Hash with Account credentials!'
      end

      begin
        response = http_post_request(@api_base, params.merge(credentials))
        Response.new(response&.body)
      rescue StandardError => e
        handle_connection_errors(e)
      end
    end

    ##
    # Raises an exception if a network error occurs. It
    # could be request timeout, socket error or anything else.
    #
    # @param error [Exception] exception object
    #
    # @raise [APIConnectionError]
    #   Failed request exception.
    def handle_connection_errors(error)
      case error
      when Timeout::Error, Errno::EINVAL, Errno::ECONNRESET
        message = "Could not connect to Alpha Card Gateway (#{@api_base}). " \
            'Please check your internet connection and try again. ' \
            'If this problem persists, you should check Alpha Card services status.'

      when SocketError
        message = 'Unexpected error communicating when trying to connect to Alpha Card Gateway. ' \
            'You may be seeing this message because your DNS is not working.'

      else
        message = 'Unexpected error communicating with Alpha Card Gateway.'
      end

      raise APIConnectionError, "#{message}\n\n(Network error: #{error.message})"
    end

    ##
    # Send secure HTTP(S) request with params to requested URL.
    #
    # @param url [String] URL
    # @param params [Hash] hash of params for the request
    #
    # @return [Net::HTTPResponse]
    #   Response of the request as HTTPResponse object
    def http_post_request(url, params)
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(params)

      http.request(request)
    end
  end
end
