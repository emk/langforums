class LanguageName < ActiveRecord::Base
  belongs_to :language
  belongs_to :in_language, class_name: 'Language'
  attr_accessible :language, :in_language, :name
end
