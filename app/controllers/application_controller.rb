class ApplicationController < ActionController::Base
  protect_from_forgery

  # Use the Devise current_user with Forem (of course).
  def forem_user
    current_user
  end
  helper_method :forem_user

  protected

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
