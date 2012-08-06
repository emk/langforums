module LanguagesHelper
  # Separate link from next.
  def sep(html)
    html + " / ".html_safe
  end
end
