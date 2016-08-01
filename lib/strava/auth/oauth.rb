require 'unirest'
require 'prius'
require 'sinatra/base'
require 'active_support/core_ext/module'

module Strava
  module Auth
    class OAuth
      REDIRECT_URI = 'http://localhost:4567/callback'.freeze

      def initialize(client_id:, client_secret:)
        @client_id = client_id
        @client_secret = client_secret
      end

      def token
        @token ||= generate_token
      end

      private

      attr_reader :client_id, :client_secret

      def generate_token
        oauth = ::Unirest.post(strava_url('oauth/token',
                                          client_id: client_id,
                                          client_secret: client_secret,
                                          code: generate_auth_code)).body
        puts("[oauth] - Identified as #{oauth['athlete']['firstname']}")
        oauth.fetch('access_token')
      end

      def generate_auth_code
        oauth_url = strava_url('oauth/authorize', {
          client_id: client_id,
          redirect_uri: REDIRECT_URI,
          response_type: 'code',
          scope: 'write,view_private',
        })

        # Asynchronously open the redirect flow url
        spawn('open', oauth_url)
        server.auth_code
      end

      # Create a server that will listen for a single HTTP request callback on localhost
      # which will save the auth code on the class, then exit.
      def server
        @server ||= Class.new(Sinatra::Base) do
          set :port, 4567

          def self.auth_code
            run! if @auth_code.nil?
            @@auth_code
          end

          get '/callback' do
            puts('[oauth] - Received access code!')
            @@auth_code = params.fetch('code')
            self.class.stop!
          end
        end
      end

      def strava_url(path, params = {})
        "https://www.strava.com/#{path}?#{URI.encode_www_form(params)}"
      end
    end
  end
end
