class LanguagesController < ApplicationController
  def index
    @query = params[:q]
    if @query.blank?
      @languages = []
    else
      inverted_name = Language.arel_table[:inverted_name]
      @languages = Language.matches(@query).major_languages_first
    end
  end
end
