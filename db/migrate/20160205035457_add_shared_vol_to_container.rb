class AddSharedVolToContainer < ActiveRecord::Migration
  def change
    add_column :containers, :shared_vol, :text
  end
end
