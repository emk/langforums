class AddHtlalLinksToLanguages < ActiveRecord::Migration
  def change
    add_column :languages, :htlal_keyword_id, :int
    add_column :languages, :htlal_language_id, :int
    add_column :languages, :htlal_profile_url, :string
  end
end
