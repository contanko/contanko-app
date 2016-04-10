class AddTemplateToTanko < ActiveRecord::Migration
  def change
    add_column :tankos, :template, :boolean
  end
end
