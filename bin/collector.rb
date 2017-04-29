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
id = 57846937
members_url = "#{api_url}groups.getMembers?group_id=#{id}&v=5.63"

puts "Start time: #{Time.now}"

users_count = Oj.load(Typhoeus.get(members_url).body)["response"]["count"]
pages_count = users_count / 1000

hydra = Typhoeus::Hydra.new(max_concurrency: 100)

requests = (0..pages_count).map { |i|
  request = Typhoeus::Request.new(members_url + "&offset=#{i}000")
  hydra.queue(request)
  request
}
hydra.run

ids = requests.map { |request|
  Oj.load(request.response.body)["response"]["items"]
}.flatten

g = Group.new
g.id = id
g.user_ids = ids
g.user_count = users_count
g.save!


puts "Stop time: #{Time.now}"
