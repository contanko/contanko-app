class CreateTankos < ActiveRecord::Migration
  def change
    create_table :tankos do |t|
      t.string :service_name
      t.text :description
      t.string :status
      t.text :metadata
      t.string :zone
      t.string :location

      t.timestamps null: false
    end
  end
end
