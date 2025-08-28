# spec/controllers/user/words_controller_spec.rb
require "rails_helper"

RSpec.describe User::WordsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let!(:user) { create(:user) }

  let!(:word_learned) do
    w = create(:word, content: "apple", word_type: :noun)
    comp = create(:component, word: w)
    create(:user_word, user: user, component: comp)
    w
  end

  let!(:word_not_learned) { create(:word, content: "banana", word_type: :noun) }

  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in user
    allow(Settings).to receive(:page_20).and_return(5)
  end

  describe "GET #index - listing words with filters & pagination" do
    context "when no params given" do
      before { get :index }

      it "responds with 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "assigns @learned_ids for current_user" do
        expect(assigns(:learned_ids)).to eq([word_learned.id])
      end
    end

    context "when filtering by status=learned" do
      before { get :index, params: { status: :learned } }

      it "returns only learned words in @words" do
        expect(assigns(:words)).to match_array([word_learned])
      end
    end

    context "when filtering by status=not_learned" do
      before { get :index, params: { status: :not_learned } }

      it "returns only not learned words in @words" do
        expect(assigns(:words)).to include(word_not_learned)
      end
    end

    context "when searching by content via ransack" do
      before { get :index, params: { q: { content_cont: "app" } } }

      it "returns words matched by query" do
        expect(assigns(:words)).to include(word_learned)
      end
    end

    context "when pagination limit applies" do
      let!(:more_words) { create_list(:word, 6) }

      before { get :index, params: { page: 1 } }

      it "limits @words by Settings.page_20" do
        expect(assigns(:words).size).to eq(5)
      end
    end
  end
end
