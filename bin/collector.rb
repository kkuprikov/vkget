require './lib/ids_collector'
require 'active_record'
require 'pg'
require 'typhoeus'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'vkget_development'
)

class User < ActiveRecord::Base
  serialize :career, JSON
  serialize :connections, JSON
  serialize :counters, JSON
  serialize :exports, JSON
  serialize :personal, JSON
  serialize :relatives, JSON
  serialize :universities, JSON
  serialize :groups, JSON
end

api_url = URI("https://api.vk.com/method/")
members_url = "#{api_url}groups.getMembers?group_id=#{id}&v=5.63"
id = 57846937

puts "Start time: #{Time.now}"

pages_count = Oj.load(Typhoeus.get(members_url).body)["response"]["count"] / 1000

hydra = Typhoeus::Hydra.new(max_concurrency: 100)

(0..pages_count).each do |i|
  request = Typhoeus::Request.new(url)
  hydra.queue(request)
  request
  # request.on_complete do |response|
  #   begin
  #     res = Oj.load(response.body)["response"]["items"]
  #   rescue 
  #     puts "Error!"
  #   end
  # end
end
hydra.run

ids = requests.map { |request|
  Oj.load(request.response.body)["response"]["items"]
}.flatten

User.where(id: ids).update_all(groups: id)

puts "Stop time: #{Time.now}"
