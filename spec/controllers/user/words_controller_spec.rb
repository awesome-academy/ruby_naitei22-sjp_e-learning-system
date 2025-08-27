require "rails_helper"

RSpec.describe User::WordsController, type: :controller do
  let!(:user) { create(:user) }

  def login_as_user
    session[:user_id] = user.id
  end

  before do
    login_as_user
    allow(Settings).to receive(:page_20).and_return(20)
  end

  # Test cho GET #index
  describe "GET #index" do
    let!(:learned_word) { create(:word, content: "learned") }
    let!(:unlearned_word) { create(:word, content: "unlearned") }
    let!(:component) { create(:word_component, word: learned_word) }
    let!(:user_word) { create(:user_word, user: user, component: component) }

    it "assigns the learned word IDs to @learned_ids" do
      get :index
      expect(assigns(:learned_ids)).to match_array([learned_word.id])
    end

    it "assigns the filtered words to @words" do
      get :index
      expect(assigns(:words)).to match_array([learned_word, unlearned_word])
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template(:index)
    end
  end
end
