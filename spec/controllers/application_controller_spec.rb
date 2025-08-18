require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  describe "#set_locale" do
    context "when a valid locale is passed" do
      it "sets the locale from params" do
        get :index, params: { locale: "en" }
        expect(I18n.locale).to eq(:en)
      end
    end

    context "when an invalid locale is passed" do
      it "sets the default locale" do
        get :index, params: { locale: "fr" }
        expect(I18n.locale).to eq(I18n.default_locale)
      end
    end
  end
end
