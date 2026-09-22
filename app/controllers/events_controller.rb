class EventsController < ApplicationController
  before_action :require_completed_profile
  before_action :require_admin!, only: %i[new create edit update destroy]
  before_action :set_event, only: %i[show edit update destroy ics]

  def index
    @events = Event.order(:starts_at)
  end

  def show
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
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:name, :description, :starts_at, :ends_at, :location)
  end

  def require_admin!
    unless current_member&.admin?
      redirect_to events_path, alert: "Admins only."
    end
  end
end