class EventsController < ApplicationController
  before_action :require_completed_profile
  before_action :require_admin!, only: %i[new create edit update destroy check_in_qr]
  before_action :set_event, only: %i[show edit update destroy ics check_in_qr]

  def check_in_qr
    unless @event.check_in_configured?
      redirect_to edit_event_path(@event), alert: "Set the event coordinates before sharing check-in."
      return
    end

    @check_in_url = event_check_in_url(@event)
    @qr_svg = RQRCode::QRCode.new(@check_in_url).as_svg(
      module_size: 5, offset: 20, color: "000", fill: "fff", use_path: true
    )
  end

  def index
    @events = Event.order(:starts_at)
  end

  def show
    return unless current_member.admin?

    @attendances = @event.attendances.where.not(checked_in_at: nil)
      .includes(:member).order(:checked_in_at, :id).to_a
  rescue ActiveRecord::ActiveRecordError => error
    Rails.logger.error("Attendance load failed for event #{@event.id}: #{error.class}")
    @attendance_load_failed = true
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    if @event.save
      redirect_to events_path, notice: "Event was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to event_path(@event), notice: "Event updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to events_path, notice: "Event deleted."
  end

  def ics
    calendar = <<~ICS
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//YourApp//EN
      BEGIN:VEVENT
      UID:event-#{@event.id}@yourapp.com
      DTSTAMP:#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}
      DTSTART:#{@event.starts_at.utc.strftime("%Y%m%dT%H%M%SZ")}
      DTEND:#{(@event.ends_at || @event.starts_at + 1.hour).utc.strftime("%Y%m%dT%H%M%SZ")}
      SUMMARY:#{@event.name}
      DESCRIPTION:#{@event.description}
      LOCATION:#{@event.location}
      END:VEVENT
      END:VCALENDAR
    ICS

    send_data calendar, type: "text/calendar", disposition: "attachment", filename: "#{@event.name.parameterize}.ics"
    rescue StandardError => e
      Rails.logger.error("ICS generation failed for event #{@event.id}: #{e.message}")
      redirect_to event_path(@event), alert: "Couldn't generate the calendar file."
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:name, :description, :starts_at, :ends_at, :location,
      :latitude, :longitude, :check_in_radius_meters, :point_value, :requirement_id,
      :other_type)
  end

  def require_admin!
    unless current_member&.admin?
      redirect_to events_path, alert: "Admins only."
    end
  end
end
