class Members::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    member = Member.from_google(**from_google_params)

    if member.present?
      sign_out_all_scopes
      sign_in_and_redirect member, event: :authentication
    else
      redirect_to new_member_session_path,
        alert: "Please sign in/up with your Texas A&M account."
    end
  end

  protected

  def after_omniauth_failure_path_for(_scope)
    new_member_session_path
  end

  private

  def from_google_params
    {
      uid: auth.uid,
      email: auth.info.email,
      first_name: auth.info.first_name,
      last_name: auth.info.last_name,
      avatar_url: auth.info.image
    }
  end

  def auth
    @auth ||= request.env["omniauth.auth"]
  end
end
