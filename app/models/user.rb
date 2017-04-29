class User < ApplicationRecord
  serialize :career, JSON
  serialize :connections, JSON
  serialize :counters, JSON
  serialize :exports, JSON
  serialize :personal, JSON
  serialize :relatives, JSON
  serialize :universities, JSON
  serialize :groups, JSON

  def groups= new_group
    gr = self.groups || []
    gr << new_group
    write_attribute(:groups, gr)
  end
end
