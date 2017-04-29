class CreateGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :groups do |t|
      t.string :name
      t.string :category
      t.integer :category_id
      t.integer :user_ids, array: true
      t.integer :user_count
      t.timestamps
    end
  end
end
