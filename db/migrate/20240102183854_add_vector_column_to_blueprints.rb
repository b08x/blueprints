class AddVectorColumnToBlueprints < ActiveRecord::Migration[7.1]
  def change
    add_column :blueprints, :embedding, :vector,
      limit: 768
  end
end
