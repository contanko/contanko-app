class AddTankoRefToContainers < ActiveRecord::Migration
  def change
    add_reference :containers, :tanko, index: true, foreign_key: true
  end
end
