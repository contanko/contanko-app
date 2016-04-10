class AddTemplateToContainer < ActiveRecord::Migration
  def change
    add_column :containers, :template, :boolean
  end
end
