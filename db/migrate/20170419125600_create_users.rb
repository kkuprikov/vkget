class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.text :groups
      t.string :first_name
      t.string :last_name
      t.date   :bdate
      t.integer :sex
      t.string :city_name
      t.integer :city_id
      t.text :career
      # t.text :connections
      t.string :skype
      t.string :facebook
      t.string :twitter
      t.string :livejournal
      t.string :instagram
      #contacts
      t.string :mobile_phone
      t.string :home_phone
      t.text :counters
      
      #country
      t.integer :country_id
      t.string :country_title
      
      t.string :domain

      # t.text :education
      t.integer :university
      t.string  :university_name
      t.integer :faculty
      t.string  :faculty_name
      t.integer :graduation
      
      t.text :exports
      t.integer :followers_count


      t.integer :has_mobile
  
      t.integer :last_seen_platform

      t.string :home_town
      
      #occupation
      t.string :occupation_type
      t.integer :occupation_id
      t.string :occupation_name
      
      
      t.text :personal
      t.text :relatives
      t.integer :relation

      # timezone
      t.text :universities

      t.timestamps
    end
  end
end
