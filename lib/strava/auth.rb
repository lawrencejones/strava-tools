require 'prius'
require_relative 'auth/oauth'

module Strava
  module Auth
    CLIENT_ID = Prius.load(:strava_client_id)
    CLIENT_SECRET = Prius.load(:strava_client_secret)
    TOKEN_FILE = File.expand_path('~/.strava-token').freeze

    def self.token
      @@token ||= self.token_from_file ||= self.token_from_oauth
    end

    def self.token_from_oauth
      OAuth.new(client_id: CLIENT_ID, client_secret: CLIENT_SECRET).token
    end

    def self.token_from_file
      File.read(TOKEN_FILE)
    rescue Errno::ENOENT
      nil
    end

    def self.token_from_file=(token_value)
      token_value.tap { File.write(TOKEN_FILE, token_value) }
    end
  end
end
