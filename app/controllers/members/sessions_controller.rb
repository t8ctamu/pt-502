class Members::SessionsController < Devise::SessionsController
  def after_sign_out_path_for(_resource_or_scope)
    new_member_session_path
  end
end