#!/usr/bin/env ruby
require 'rubygems'
require 'faraday'
$base_url = 'http://0.0.0.0:4000'
puts "Enter ID that you want to test removal? "
id  = gets.chomp
@conn = Faraday.new(:url => $base_url) do |faraday|
  faraday.response :logger                  # log requests to STDOUT
  faraday.request  :url_encoded             # form-encode POST params
  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end


def get_token
  response = @conn.get '/'
  raise 'CSRF Token not found' unless response.body.match(/meta content="([^"]+)" name="csrf-token"/)
  @token = $1
  @cookie = response.headers['set-cookie'].split('; ').first
end

def remove_picture(id)
  get_token
  @conn.delete "/ckeditor/pictures/#{id}.json", { authenticity_token: @token } do |response|
    response.headers['Accept'] = 'text/html'
    response.headers['Content-Type'] = 'application/x-www-form-urlencoded'
    response.headers['Cookie'] = @cookie
  end
end

response = remove_picture(id)

puts case response.status.to_s
  when /50./
    CanCan::AccessDenied 
  when /40./
    "#{response.status} Unauthorized"
  when /20./
    "#{response.status} Success"
  else
   response.status 
  end
