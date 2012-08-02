class Language < ActiveRecord::Base
  attr_accessible :inverted_name, :iso_639_1, :iso_639_2b, :iso_639_2t, :iso_639_3, :name, :iso_639_scope, :iso_639_type

  # Enforce field sizes.
  validates :iso_639_1, length: { is: 2, allow_nil: true }
  validates :iso_639_2t, length: { is: 3, allow_nil: true }
  validates :iso_639_2b, length: { is: 3, allow_nil: true }
  validates :iso_639_3, length: { is: 3, allow_nil: true }
  validates :iso_639_scope, length: { is: 1, allow_nil: true }
  validates :iso_639_type, length: { is: 1, allow_nil: true }

  # Return the best ISO 639 code for this language.
  def iso_639
    iso_639_1 || iso_639_2t || iso_639_2b || iso_639_3
  end

  # Link to an external language database.
  def external_link
    "http://en.wikipedia.org/wiki/ISO_639:#{iso_639}"
  end
end
