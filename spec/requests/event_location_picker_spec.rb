require "rails_helper"

# Acceptance criteria for the event location picker.
#
# Assumptions to adjust for your app:
#   * Uses your :member factory traits (:admin, :profile_completed) and Devise's `sign_in`.
RSpec.describe "Event location picker", type: :request do
     let(:officer) { create(:member, :admin, :profile_completed) }
  let(:regular_member) { create(:member, :profile_completed) }
  let(:geocoder) { instance_double(Geocoding::Nominatim) }

  let(:valid_attributes) do
       {
         name: "Weekly meeting",
         description: "Agenda",
         starts_at: 2.days.from_now,
         location: "Student Center, 100 Campus Dr",
         latitude: "30.610000",
         longitude: "-96.340000",
         check_in_radius_feet: 250,
         point_value: 1
       }
  end

  let(:json_headers) { { "Accept" => "application/json" } }

  before do
       allow(Geocoding::Nominatim).to receive(:new).and_return(geocoder)
  end

  # -------------------------------------------------------------------------
  describe "Acceptance criterion 1 (sunny): pick a location without typing coordinates" do
       before { sign_in(officer) }

    it "suggests matching places when the officer searches" do
         allow(geocoder).to receive(:search).with("student center").and_return(
           [ { label: "Student Center, 100 Campus Dr", latitude: 30.61, longitude: -96.34 } ]
         )

      get location_search_events_path, params: { q: "student center" }, headers: json_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["results"]).to contain_exactly(
        include("label" => "Student Center, 100 Campus Dr", "latitude" => 30.61, "longitude" => -96.34)
      )
    end

    it "gives a readable name for a pin dropped or dragged on the map" do
         allow(geocoder).to receive(:reverse).with(30.61, -96.34)
           .and_return({ label: "Student Center, 100 Campus Dr", latitude: 30.61, longitude: -96.34 })

      get location_search_events_path, params: { lat: "30.61", lng: "-96.34" }, headers: json_headers

      expect(response.parsed_body["results"].first["label"]).to eq("Student Center, 100 Campus Dr")
    end

    it "shows the map, search box and saved list, with no raw latitude/longitude inputs" do
         SavedLocation.create!(name: "PT Clinic", latitude: 30.62, longitude: -96.33)

      get new_event_path

      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('[data-controller="location-picker"]')).to be_present
      expect(doc.at_css('[data-location-picker-target="map"]')).to be_present
      expect(doc.at_css('[data-location-picker-target="query"]')).to be_present
      expect(doc.at_css('option[data-name="PT Clinic"]')).to be_present
      expect(doc.at_css('input[name="event[latitude]"]')["type"]).to eq("hidden")
      expect(doc.at_css('input[name="event[longitude]"]')["type"]).to eq("hidden")
    end

    it "stores coordinates in the background and shows members a readable location" do
         expect {
              post events_path, params: { event: valid_attributes }
         }.to change(Event, :count).by(1)

      event = Event.order(:id).last
      expect(event.location).to eq("Student Center, 100 Campus Dr")
      expect(event.latitude.to_f).to eq(30.61)
      expect(event.longitude.to_f).to eq(-96.34)

      sign_out officer
      sign_in regular_member
      get event_path(event)
      expect(response.body).to include("Student Center, 100 Campus Dr")
      expect(response.body).not_to include("30.61")
    end

    it "can add the chosen spot to the commonly used list" do
         expect {
              post events_path, params: { event: valid_attributes, save_as_location: "1" }
         }.to change(SavedLocation, :count).by(1)

      expect(SavedLocation.last.name).to eq("Student Center, 100 Campus Dr")
    end
  end

  # -------------------------------------------------------------------------
  describe "Acceptance criterion 2 (rainy): clear messages and never a bad location" do
       context "as an officer" do
            before { sign_in(officer) }

         it "reports a search with no results as an empty list the picker turns into a clear message" do
              allow(geocoder).to receive(:search).and_return([])

           get location_search_events_path, params: { q: "zzzzzz" }, headers: json_headers

           expect(response).to have_http_status(:ok)
           expect(response.parsed_body["results"]).to eq([])

           get new_event_path
           expect(response.body).to include("No locations found, try a different search.")
         end

         it "returns a friendly error, not a stack trace, when the geocoder is down" do
              allow(geocoder).to receive(:search).and_raise(Geocoding::Error, "timeout")

           get location_search_events_path, params: { q: "student center" }, headers: json_headers

           expect(response).to have_http_status(:service_unavailable)
           expect(response.parsed_body["error"]).to match(/Choose from the list or try again later/)
         end

         it "rejects a too-short search without calling the geocoder" do
              expect(geocoder).not_to receive(:search)

           get location_search_events_path, params: { q: "ab" }, headers: json_headers

           expect(response).to have_http_status(:unprocessable_entity)
           expect(response.parsed_body["error"]).to match(/at least 3 characters/)
         end

         it "ships a clear map-failure message and keeps the saved list available" do
              SavedLocation.create!(name: "PT Clinic", latitude: 30.62, longitude: -96.33)

           get new_event_path

           expect(response.body).to include(
             "The map could not be loaded. Choose from the list or try again later."
           )
           expect(Nokogiri::HTML(response.body).at_css('option[data-name="PT Clinic"]')).to be_present
         end

         it "does not save an event with no location selected" do
              attrs = valid_attributes.merge(location: "", latitude: "", longitude: "")

           expect { post events_path, params: { event: attrs } }.not_to change(Event, :count)

           expect(response).to have_http_status(:unprocessable_entity)
           expect(response.body).to include("Choose a location on the map before saving.")
         end

         it "does not save an event with a pin but no readable name" do
              attrs = valid_attributes.merge(location: "")

           expect { post events_path, params: { event: attrs } }.not_to change(Event, :count)
           expect(response).to have_http_status(:unprocessable_entity)
         end

         it "does not save incorrect coordinates" do
              [
                { latitude: "91", longitude: "-96.34" },
                { latitude: "30.61", longitude: "-181" },
                { latitude: "abc", longitude: "-96.34" }
              ].each do |bad|
                   expect {
                        post events_path, params: { event: valid_attributes.merge(bad) }
                   }.not_to change(Event, :count)
              end
         end

         it "does not let an edit wipe out an existing location" do
              event = Event.create!(valid_attributes)

           patch event_path(event), params: { event: { location: "", latitude: "", longitude: "" } }

           expect(response).to have_http_status(:unprocessable_entity)
           event.reload
           expect(event.location).to eq("Student Center, 100 Campus Dr")
           expect(event.latitude.to_f).to eq(30.61)
         end
       end

    context "as a regular member (officers only)" do
         before { sign_in(regular_member) }

      it "cannot use location search" do
           expect(geocoder).not_to receive(:search)

        get location_search_events_path, params: { q: "student center" }, headers: json_headers

        expect(response).to have_http_status(:forbidden)
      end

      it "cannot open the form or create an event" do
           get new_event_path
        expect(response).to redirect_to(events_path)

        expect {
             post events_path, params: { event: valid_attributes }
        }.not_to change(Event, :count)
      end

      it "cannot change an event's location" do
           event = Event.create!(valid_attributes)

        patch event_path(event), params: { event: { location: "Elsewhere", latitude: "1", longitude: "1" } }

        expect(response).to redirect_to(events_path)
        expect(event.reload.location).to eq("Student Center, 100 Campus Dr")
      end
    end
  end
end
