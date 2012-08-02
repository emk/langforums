class Language < ActiveRecord::Base
  attr_accessible :inverted_name, :iso_639_1, :iso_639_2b, :iso_639_2t, :iso_639_3, :name, :iso_639_scope, :iso_639_type

  # Enforce field sizes.
  validates :iso_639_1, length: { is: 2, allow_nil: true }
  validates :iso_639_2t, length: { is: 3, allow_nil: true }
  validates :iso_639_2b, length: { is: 3, allow_nil: true }
  validates :iso_639_3, length: { is: 3, allow_nil: true }
  validates :iso_639_scope, length: { is: 1, allow_nil: true }
  validates :iso_639_type, length: { is: 1, allow_nil: true }
end
