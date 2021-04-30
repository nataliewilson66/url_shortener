class CreateTaggings < ActiveRecord::Migration[6.1]
  def change
    create_table :taggings do |t|
      t.integer :topic_id
      t.integer :shortened_url_id

      t.timestamps
    end
    
    add_index :taggings, [:topic_id, :shortened_url_id]
  end
end
