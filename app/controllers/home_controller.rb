class HomeController < ApplicationController
  before_action :require_completed_profile

  def index
    @upcoming_events = Event.where("starts_at >= ?", Time.current)
                             .order(:starts_at)
                             .limit(3)
  end
end