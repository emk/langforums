class CreateLanguages < ActiveRecord::Migration
  def up
    create_table :languages do |t|
      t.references :macrolanguage
      t.string :iso_639_1, limit: 2
      t.string :iso_639_2t, limit: 3
      t.string :iso_639_2b, limit: 3
      t.string :iso_639_3, limit: 3
      t.string :iso_639_scope, limit: 1
      t.string :iso_639_type, limit: 1
      t.string :name, null: false
      t.string :inverted_name

      t.timestamps
    end

    add_index :languages, :macrolanguage_id
    add_index :languages, :iso_639_1
    add_index :languages, :iso_639_2t
    add_index :languages, :iso_639_2b
    add_index :languages, :iso_639_3
    add_index :languages, :name
    add_index :languages, :inverted_name
  end

  def down
    drop_table :languages
  end
end
