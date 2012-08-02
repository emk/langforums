class AddCodesToLanguages < ActiveRecord::Migration
  def change
    add_column :languages, :code, :string
    add_column :languages, :alt_code, :string
    add_index :languages, :code, unique: true
    add_index :languages, :alt_code
  end
end
