class SubmissionReviewsController < ApplicationController
     before_action :require_completed_profile
  before_action :require_admin

  def index
       @submissions = EventSubmission.pending.includes(:member, :requirement).order(:created_at)
  end

  def approve
       submission = EventSubmission.find(params[:id])
       points = Integer(params[:points].to_s, exception: false)

       if points.nil? || points <= 0
            return redirect_to submission_reviews_path, alert: "Enter a whole number of points greater than 0."
       end

       submission.approve!(reviewer: current_member, points: points)
       redirect_to submission_reviews_path,
         notice: "Approved. #{points} #{submission.requirement.name} point(s) added for #{submission.member.first_name}."
     rescue EventSubmission::AlreadyReviewed
          redirect_to submission_reviews_path, alert: "That request was already reviewed."
     rescue ActiveRecord::RecordNotFound
          redirect_to submission_reviews_path, alert: "Request not found."
     rescue StandardError => e
          Rails.logger.error("Submission approval failed: #{e.class}: #{e.message}")
       redirect_to submission_reviews_path,
         alert: "Approval could not be saved. The request is still pending and no points were added."
  end

  def deny
       submission = EventSubmission.find(params[:id])
       reason = params[:reason].to_s.strip

       return redirect_to submission_reviews_path, alert: "Enter a reason for denying." if reason.blank?

       submission.deny!(reviewer: current_member, reason: reason)
       redirect_to submission_reviews_path, notice: "Request denied."
     rescue EventSubmission::AlreadyReviewed
          redirect_to submission_reviews_path, alert: "That request was already reviewed."
     rescue ActiveRecord::RecordNotFound
          redirect_to submission_reviews_path, alert: "Request not found."
     rescue StandardError => e
          Rails.logger.error("Submission denial failed: #{e.class}: #{e.message}")
       redirect_to submission_reviews_path, alert: "The denial could not be saved. The request is still pending."
  end
end
