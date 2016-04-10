class AddDependsOnToContainer < ActiveRecord::Migration
  def change
    add_column :containers, :depends_on, :string
  end
end
