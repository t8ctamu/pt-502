class EventSubmissionsController < ApplicationController
  before_action :require_completed_profile

  def new
    @submission = EventSubmission.new
  end

  def create
    @submission = current_member.event_submissions.build(submission_params)

    if @submission.save
      redirect_to root_path, notice: "Submission sent. It shows as pending until an officer reviews it."
    else
      flash.now[:alert] = "Please fill in all required fields and fix the errors below."
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    @submission.errors.add(:base, "You already submitted this event.")
    flash.now[:alert] = "Your submission could not be sent."
    render :new, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("Event submission failed: #{e.class}: #{e.message}")
    @submission ||= EventSubmission.new
    flash.now[:alert] = "Your submission could not be sent, try again or contact an officer."
    render :new, status: :internal_server_error
  end

  private

  def submission_params
    params.require(:event_submission).permit(:name, :event_date, :requirement_id, :description)
  end
end