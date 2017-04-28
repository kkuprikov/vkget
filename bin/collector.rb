require './lib/ids_collector'
require 'active_record'
require 'pg'

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

c = IdsCollector.new

c.collect_ids [(User.last.id / 1000000) + 1]
