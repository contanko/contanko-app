class AddPersistantVolsToContainer < ActiveRecord::Migration
  def change
    add_column :containers, :persistant_vols, :string
  end
end
