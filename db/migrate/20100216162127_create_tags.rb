class CreateTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.string :name
      t.boolean :is_facet
      t.string :status
      t.string :nature
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :tags
  end
end