require 'addressable/uri'
require 'http'
require 'http/form_data'
require 'json'
require 'openssl'
require 'twitter/error'
require 'twitter/rate_limit'
require 'twitter/utils'
require 'twitter/rest/request_options'

module Twitter
  module REST
    class Request
      include Twitter::Utils
      include Twitter::REST::RequestOptions
      BASE_URL = 'https://api.twitter.com'.freeze
      attr_accessor :client, :headers, :options, :path, :rate_limit,
                    :request_method, :uri, :options_key
      alias verb request_method

      # @param client [Twitter::Client]
      # @param request_method [String, Symbol]
      # @param path [String]
      # @param options [Hash]
      # @return [Twitter::REST::Request]
      def initialize(client, request_method, path, options = {})
        @client = client
        @uri = Addressable::URI.parse(path.start_with?('http') ? path : BASE_URL + path)
        create_request_options!(request_method, options)
        @path = uri.path
        @options = options
      end

      # @return [Array, Hash]
      def perform
        response = http_client.headers(@headers).public_send(@request_method, @uri.to_s, @options_key => @options)
        response_body = response.body.empty? ? '' : symbolize_keys!(response.parse)
        response_headers = response.headers
        fail_or_return_response_body(response.code, response_body, response_headers)
      end

    private

      def fail_or_return_response_body(code, body, headers)
        error = error(code, body, headers)
        raise(error) if error
        @rate_limit = Twitter::RateLimit.new(headers)
        body
      end

      def error(code, body, headers)
        klass = Twitter::Error::ERRORS[code]
        if klass == Twitter::Error::Forbidden
          forbidden_error(body, headers)
        elsif !klass.nil?
          klass.from_response(body, headers)
        end
      end

      def forbidden_error(body, headers)
        error = Twitter::Error::Forbidden.from_response(body, headers)
        klass = Twitter::Error::FORBIDDEN_MESSAGES[error.message]
        if klass
          klass.from_response(body, headers)
        else
          error
        end
      end

      def symbolize_keys!(object)
        if object.is_a?(Array)
          object.each_with_index do |val, index|
            object[index] = symbolize_keys!(val)
          end
        elsif object.is_a?(Hash)
          object.dup.each_key do |key|
            object[key.to_sym] = symbolize_keys!(object.delete(key))
          end
        end
        object
      end

      # @return [HTTP::Client, HTTP]
      def http_client
        client = @client.proxy ? HTTP.via(*proxy) : HTTP
        client = client.timeout(:per_operation, connect: @client.timeouts[:connect], read: @client.timeouts[:read], write: @client.timeouts[:write]) if @client.timeouts
        client
      end

      # Return proxy values as a compacted array
      #
      # @return [Array]
      def proxy
        @client.proxy.values_at(:host, :port, :username, :password).compact
      end
    end
  end
end
