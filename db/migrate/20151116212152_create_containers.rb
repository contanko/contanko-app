class CreateContainers < ActiveRecord::Migration
  def change
    create_table :containers do |t|
      t.string :instance_name
      t.string :instance_size
      t.string :instance_type
      t.string :ports
      t.string :env_vars
      t.text :metadata
      t.string :instance_link
      t.string :image_name
      t.text :unit_file
      t.text :description
      t.string :status

      t.timestamps null: false
    end
  end
end
