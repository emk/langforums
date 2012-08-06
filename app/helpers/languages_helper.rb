module LanguagesHelper
  # Wrap HTML in parantheses.
  def parens(html)
    "(".html_safe + html + ")".html_safe
  end
end
