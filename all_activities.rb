require 'oauth'
require 'uri'
require 'sinatra/base'
require 'pry'
require 'unirest'
require 'strava/api/v3'

module Strava
  class Authorizer < Sinatra::Base
    TOKEN_FILE = File.join(ENV['HOME'], '.strava_token')

    def self.get_token
      @@token = token_from_file || token_from_oauth
    end

    def self.token_from_file
      File.read(TOKEN_FILE).to_s if File.exist?(TOKEN_FILE)
    end

    def self.token_from_oauth
      token = OAuth.access_token
      File.write(TOKEN_FILE, token)
      token
    end
  end

  class OAuth < Sinatra::Base
    CLIENT_ID = 8829
    CLIENT_SECRET = '59cbd641318371f8743b111a3878fb6a9857ec20'
    @@auth_code = nil

    def self.access_token
      oauth = Unirest.post('https://www.strava.com/oauth/token',
                           parameters: { client_id: CLIENT_ID,
                                         client_secret: CLIENT_SECRET,
                                         code: auth_code }).body

      puts "[oauth] - Identified as #{oauth['firstname']} #{oauth['lastname']}"
      oauth['access_token']
    end

    def self.auth_code
      return @@auth_code unless @@auth_code.nil?

      strava_oauth_url = 'https://www.strava.com/oauth/authorize?' + URI.encode_www_form({
        client_id: CLIENT_ID,
        redirect_uri: 'http://localhost:4567/callback',
        response_type: 'code',
        scope: 'write,view_private',
      })

      spawn('open', strava_oauth_url)
      self.run!

      raise 'Error fetching access code' if @@auth_code.nil?

      @@auth_code
    end

    get '/callback' do
      puts('[oauth] - Received access code!')
      @@auth_code = params.fetch('code')
      self.class.stop!
    end
  end
end

def strava_get(url, token, **params)
  Unirest.get('https://www.strava.com/api/v3' + url,
              parameters: params,
              headers: { 'Authorization' => "Bearer #{token}" }).body
end

def strava_put(url, token, **params)
  Unirest.put('https://www.strava.com/api/v3' + url,
              parameters: params,
              headers: { 'Authorization' => "Bearer #{token}" }).body
end

token = Strava::Authorizer.get_token
strava_get('/athlete/activities', token, per_page: 200).
  select { |a| a['type'] == 'StandUpPaddling' || a['type'] == 'WaterSport' }.
  each do |activity|
    puts "Correcting activity #{activity['id']}..."
    strava_put("/activities/#{activity['id']}", token, type: 'Rowing')
  end


