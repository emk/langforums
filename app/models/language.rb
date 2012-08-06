class Language < ActiveRecord::Base
  has_many :language_names
  has_many(:names_of_other_languages, class_name: 'LanguageName',
           foreign_key: 'in_language_id')

  attr_accessible :inverted_name, :iso_639_1, :iso_639_2b, :iso_639_2t
  attr_accessible :iso_639_3, :alt_code, :name, :iso_639_scope, :iso_639_type

  # Validations.
  validates :code, length: { minimum: 2, maximum: 3 }, uniqueness: true
  validates :iso_639_1, length: { is: 2, allow_nil: true }, uniqueness: { allow_nil: true }
  validates :iso_639_2t, length: { is: 3, allow_nil: true }, uniqueness: { allow_nil: true }
  validates :iso_639_2b, length: { is: 3, allow_nil: true }, uniqueness: { allow_nil: true }
  validates :iso_639_3, length: { is: 3, allow_nil: true }, uniqueness: { allow_nil: true }
  validates :iso_639_scope, length: { is: 1, allow_nil: true }
  validates :iso_639_type, length: { is: 1, allow_nil: true }
  validates :name, uniqueness: true
  validates :inverted_name, uniqueness: true

  # Search for a language.  This function may eventually become more
  # sophisticated.
  scope(:matches, lambda do |query|
    where(Language.arel_table[:inverted_name].matches("%#{query}%"))
  end)

  # Place ISO 639-1 languages first, because they're popular, and alphabetize
  # things otherwise.
  scope :major_languages_first, order('iso_639_1 IS NULL', :inverted_name)

  # Set up a sensible primary key that we can use in the UI.
  before_validation do
    self.code = iso_639
  end

  # Return the best ISO 639 code for this language.
  def iso_639
    iso_639_1 || iso_639_2t || iso_639_2b || iso_639_3
  end

  # Link to an external language database.
  def wikipedia_url
    "http://en.wikipedia.org/wiki/ISO_639:#{iso_639}"
  end

  # Link to Ethnologue database
  def ethnologue_url
    "http://www.ethnologue.com/show_language.asp?code=#{iso_639_3}"
  end

  # Link to various maps.  Some of the major language maps have problems
  def llmap_url
    "http://llmap.org/languages/#{iso_639_3}.html"
  end

  # Stored directly in database.
  #htlal_profile_url

  # The most popular threads on HTLAL.
  def htlal_threads_url
    if htlal_keyword_id
      "http://how-to-learn-any-language.com/forum/keyword.asp?KW=#{htlal_keyword_id}"
    else
      nil
    end
  end

  # A list of everybody who knows or studies this language on HTLAL.
  def htlal_users_url
    if htlal_language_id
      "http://how-to-learn-any-language.com/forum/languages.asp?language=#{htlal_language_id}"
    end
  end

  # Our own wiki profiles.
  def htlal_wiki_url
    "http://learnanylanguage.wikia.com/wiki/#{name.gsub(' ', '_')}"
  end
end
