class HomeController < ApplicationController
  before_action :require_completed_profile

  def index
  end
end