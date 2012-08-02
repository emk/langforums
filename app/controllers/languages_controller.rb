class LanguagesController < ApplicationController
  def index
    @query = params[:q]
    if @query.blank?
      @languages = []
    else
      inverted_name = Language.arel_table[:inverted_name]
      @languages = Language.where(inverted_name.matches("%#{@query}%")).
        order('iso_639_1 IS NULL', :inverted_name)
    end
  end
end
