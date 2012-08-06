class CreateLanguageNames < ActiveRecord::Migration
  def change
    create_table :language_names do |t|
      t.references :language
      t.references :in_language
      t.string :name

      t.timestamps
    end
    add_index :language_names, :language_id
    add_index :language_names, :in_language_id
    add_index :language_names, :name
  end
end
