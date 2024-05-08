require 'json'
require 'rest-client'
require 'urbanairship'
require 'jwt'


module Urbanairship
    class Client
      attr_accessor :key, :secret, :token
      include Urbanairship::Common
      include Urbanairship::Loggable

      # Initialize the Client
      #
      # @param [Object] key Application Key
      # @param [Object] secret Application Secret
      # @param [String] server Airship server to use ("api.asnapieu.com" for EU or "api.asnapius.com" for US).
      #                        Used only when the request is sent with a "path", not an "url".
      # @param [String] token Application Auth Token
      # @param [Object] oauth Oauth object
      # @return [Object] Client
      def initialize(key: required('key'), secret: nil, server: Urbanairship.configuration.server, token: nil, oauth: nil)
        @key = key
        @secret = secret
        @server = server
        @token = token
        @oauth = oauth

        if @oauth != nil && @token != nil
          raise ArgumentError.new("oauth and token can't both be used at the same time.")
        end
      end

      # Send a request to Airship's API
      #
      # @param [Object] method HTTP Method
      # @param [Object] body Request Body
      # @param [Object] path Request path
      # @param [Object] url Request URL
      # @param [Object] content_type Content-Type
      # @param [Object] encoding Encoding
      # @param [Symbol] auth_type (:basic|:bearer)
      # @return [Object] Push Response
      def send_request(method: required('method'), path: nil, url: nil, body: nil,
                       content_type: nil, encoding: nil, auth_type: :basic)
        req_type = case method
          when 'GET'
            :get
          when 'POST'
            :post
          when 'PUT'
            :put
          when 'DELETE'
            :delete
          else
            fail 'Method was not "GET" "POST" "PUT" or "DELETE"'
        end

        raise ArgumentError.new("path and url can't be both nil") if path.nil? && url.nil?

        headers = {'User-Agent' => 'UARubyLib/' + Urbanairship::VERSION + ' ' + @key}
        headers['Accept'] = 'application/vnd.urbanairship+json; version=3'
        headers['Content-Type'] = content_type unless content_type.nil?
        headers['Content-Encoding'] = encoding unless encoding.nil?

        unless @oauth.nil?
          begin
            @token = @oauth.get_token
          rescue RestClient::Exception => e
            new_error = RestClient::Exception.new(e.response, e.response.code)
            new_error.message = "error while getting oauth token: #{e.message}"
            raise new_error
          end
        end

        if @token != nil
          auth_type = :bearer
        end

        if auth_type == :bearer
          raise ArgumentError.new('token must be provided as argument if auth_type=bearer') if @token.nil?
          headers['X-UA-Appkey'] = @key
          headers['Authorization'] = "Bearer #{@token}"
        end

        url = "https://#{@server}/api#{path}" unless path.nil?

        debug = "Making #{method} request to #{url}.\n"+ "\tHeaders:\n"
        debug += "\t\tcontent-type: #{content_type}\n" unless content_type.nil?
        debug += "\t\tcontent-encoding: gzip\n" unless encoding.nil?
        debug += "\t\taccept: application/vnd.urbanairship+json; version=3\n"
        debug += "\tBody:\n#{body}" unless body.nil?

        logger.debug(debug)

        params = {
          method: method,
          url: url,
          headers: headers,
          payload: body,
          timeout: Urbanairship.configuration.timeout
        }

        if auth_type == :basic
          raise ArgumentError.new('secret must be provided as argument if auth_type=basic') if @secret.nil?
          params[:user] = @key
          params[:password] = @secret
        end

        response = RestClient::Request.execute(params)

        logger.debug("Received #{response.code} response. Headers:\n\t#{response.headers}\nBody:\n\t#{response.body}")
        Response.check_code(response.code, response)

        self.class.build_response(response)
      end

      # Create a Push Object
      #
      # @return [Object] Push Object
      def create_push
        Push::Push.new(self)
      end

      # Create a Scheduled Push Object
      #
      # @return [Object] Scheduled Push Object
      def create_scheduled_push
        Push::ScheduledPush.new(self)
      end

      # Build a hash from the response object
      #
      # @return [Hash] The response body.
      def self.build_response(response)
        response_hash = {'code'=>response.code.to_s, 'headers'=>response.headers}

        begin
          body = JSON.parse(response.body)
        rescue JSON::ParserError
          if response.body.nil? || response.body.empty?
            body = {}
          else
            body = response.body
            response_hash['error'] = 'could not parse response JSON'
          end
        end

        response_hash['body'] = body
        response_hash
      end
    end
  end
