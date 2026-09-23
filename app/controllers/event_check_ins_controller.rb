class EventCheckInsController < ApplicationController
  prepend_before_action :remember_check_in, only: :show
  before_action :set_event

  def show
    @attendance = current_member.attendances.find_by(event: @event)
  end

  def create
    attendance = EventCheckIn.call(member: current_member, event: @event,
      latitude: params[:latitude], longitude: params[:longitude])
    redirect_to event_check_in_path(@event), status: :see_other,
      notice: "You're marked present! #{helpers.pluralize(attendance.points_awarded, 'point')} added to your total."
  rescue EventCheckIn::Rejected => error
    @check_in_error = error.message
    @attendance = current_member.attendances.find_by(event: @event)
    render :show, status: :unprocessable_entity
  end

  private

  def remember_check_in
    store_location_for(:member, request.fullpath) unless member_signed_in?
  end

  def set_event
    @event = Event.find(params[:event_id])
  end
end
