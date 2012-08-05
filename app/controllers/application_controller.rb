class ApplicationController < ActionController::Base
  # Languages in which we will attempt to display the site.
  AVAILABLE_LANGUAGES = %w(bg de en es fa fr it nl pl pt-BR pt-PT ru sv zh-CN)

  protect_from_forgery
  before_filter :set_locale

  # Use the Devise current_user with Forem (of course).
  def forem_user
    current_user
  end
  helper_method :forem_user

  protected

  # Configure our locale appropriately, using either a cookie set by
  # JavaScript, or by asking the user's browser which language is best.
  def set_locale
    available = TRANSLATIONS.map(&:code)
    puts "Cookie: #{cookies[:locale]}"
    if cookies[:locale] && available.include?(cookies[:locale])
      selected = cookies[:locale]
    end
    I18n.locale = selected ||
      http_accept_language.preferred_language_from(available) ||
      I18n.default_locale
  end

  # Store HTML editor resources on a per-user basis.
  def ckeditor_filebrowser_scope(options = {})
    super({ :assetable_id => current_user.id, :assetable_type => 'User' }
      .merge(options))
  end

  # CanCan integration for ckeditor.
  # XXX: Hook this up properly.
  def ckeditor_authenticate
    authorize! action_name, @asset
  end

  # Associate current user with our ckeditor asset.
  def ckeditor_before_create_asset(asset)
    asset.assetable = current_user
    return true
  end
end
