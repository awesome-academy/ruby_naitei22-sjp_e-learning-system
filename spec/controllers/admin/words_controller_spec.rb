require "rails_helper"

RSpec.describe Admin::WordsController, type: :controller do
  let!(:admin_user) { create(:user, role: "admin") }

  def login_as_admin
    session[:user_id] = admin_user.id
  end

  before do
    login_as_admin
  end

  let!(:word1) { create(:word, content: "apple", created_at: Time.zone.now.beginning_of_day) }
  let!(:word2) { create(:word, content: "banana", created_at: 1.day.ago) }
  let!(:word3) { create(:word, content: "orange", created_at: 7.days.ago) }
  let!(:word4) { create(:word, content: "grape", created_at: 30.days.ago) }
  let!(:word5) { create(:word, content: "pineapple", created_at: 31.days.ago) }

  # Test cho action index
  describe "GET #index" do
    context "without params" do
      before { get :index }

      it "assigns all words and sorts by recent" do
        expect(assigns(:words)).to eq([word1, word2, word3, word4, word5])
      end

      it "renders the index template" do
        expect(response).to render_template(:index)
      end
    end

    context "with query param" do
      it "filters words by content" do
        get :index, params: { query: "apple" }
        expect(assigns(:words)).to match_array([word1, word5])
      end
    end

    describe "with filter_time param" do
      it "filters words created today" do
        get :index, params: { filter_time: :today }
        expect(assigns(:words)).to eq([word1])
      end

      it "filters words created in the last 7 days" do
        get :index, params: { filter_time: :last_7_days }
        expect(assigns(:words)).to match_array([word1, word2, word3])
      end

      it "filters words created in the last 30 days" do
        get :index, params: { filter_time: :last_30_days }
        expect(assigns(:words)).to match_array([word1, word2, word3, word4])
      end

      it "returns all words with an invalid filter" do
        get :index, params: { filter_time: :invalid_filter }
        expect(assigns(:words)).to match_array([word1, word2, word3, word4, word5])
      end
    end
  end

  # Test cho action new
  describe "GET #new" do
    before { get :new }

    it "assigns a new word" do
      expect(assigns(:word)).to be_a_new(Word)
    end
    it "renders the new template" do
      expect(response).to render_template(:new)
    end
  end

  # Test cho action create
  describe "POST #create" do
    context "with valid params" do
      let(:word_params) { { word: attributes_for(:word, content: "test", meaning: "test meaning", word_type: :noun) } }

      it "creates a new word" do
        expect { post :create, params: word_params }.to change(Word, :count).by(1)
      end

      it "assigns the correct content to the new word" do
        post :create, params: word_params
        new_word = Word.last
        expect(new_word.content).to eq("test")
      end

      it "assigns the correct meaning to the new word" do
        post :create, params: word_params
        new_word = Word.last
        expect(new_word.meaning).to eq("test meaning")
      end

      it "assigns the correct word_type to the new word" do
        post :create, params: word_params
        new_word = Word.last
        expect(new_word.word_type).to eq("noun")
      end

      it "sets a flash message" do
        post :create, params: word_params
        expect(flash[:success]).to eq(I18n.t("admin.words.create.success"))
      end

      it "redirects to index" do
        post :create, params: word_params
        expect(response).to redirect_to(admin_words_path)
      end
    end

    context "with invalid params" do
      let(:invalid_word_params) { { word: attributes_for(:word, content: nil) } }

      before { post :create, params: invalid_word_params }

      it "does not create a new word" do
        expect { post :create, params: invalid_word_params }.not_to change(Word, :count)
      end

      it "renders the new template" do
        expect(response).to render_template(:new)
      end

      it "returns unprocessable_entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with unauthorized params" do
      let(:unauthorized_params) { { word: attributes_for(:word, content: "test", unauthorized_param: "malicious") } }

      it "creates a new word" do
        expect { post :create, params: unauthorized_params }.to change(Word, :count).by(1)
      end

      it "does not assign unauthorized params to the new word" do
        post :create, params: unauthorized_params
        new_word = Word.last
        expect(new_word).not_to respond_to(:unauthorized_param)
      end

      it "assigns the correct content to the new word" do
        post :create, params: unauthorized_params
        new_word = Word.last
        expect(new_word.content).to eq("test")
      end

      it "sets a flash message" do
        post :create, params: unauthorized_params
        expect(flash[:success]).to eq(I18n.t("admin.words.create.success"))
      end

      it "redirects to index" do
        post :create, params: unauthorized_params
        expect(response).to redirect_to(admin_words_path)
      end
    end
  end

  # Test cho action edit
  describe "GET #edit" do
    context "when word exists" do
      before { get :edit, params: { id: word1.id } }

      it "assigns the requested word" do
        expect(assigns(:word)).to eq(word1)
      end
      it "renders the edit template" do
        expect(response).to render_template(:edit)
      end
    end

    context "when word does not exist" do
      before { get :edit, params: { id: -1 } }

      it "redirects to index" do
        expect(response).to redirect_to(admin_words_path)
      end
      it "sets a flash message" do
        expect(flash[:danger]).to eq(I18n.t("not_found"))
      end
    end
  end

  # Test cho action update
  describe "PATCH #update" do
    let(:new_content) { { content: "updated_content" } }

    let(:new_meaning) { {meaning: "updated_meaning"} }

    let(:new_word_type) { {word_type: "adjective"} }

    context "with valid params" do
      it "updates the content in the database" do
        patch :update, params: { id: word1.id, word: new_content }
        word1.reload
        expect(word1.content).to eq("updated_content")
      end

      it "updates the word_type in the database" do
        patch :update, params: { id: word1.id, word: new_word_type }
        word1.reload
        expect(word1.word_type).to eq("adjective")
      end

      it "updates the meaning in the database" do
        patch :update, params: { id: word1.id, word: new_meaning }
        word1.reload
        expect(word1.meaning).to eq("updated_meaning")
      end

      it "sets a success flash message" do
        patch :update, params: { id: word1.id, word: new_content }
        expect(flash[:success]).to eq(I18n.t("admin.words.update.success"))
      end

      it "redirects to the index page" do
        patch :update, params: { id: word1.id, word: new_content }
        expect(response).to redirect_to(admin_words_path)
      end
    end

    context "with invalid params" do
      let(:invalid_attributes) { { content: nil } }

      before { patch :update, params: { id: word1.id, word: invalid_attributes } }

      it "does not update the word" do
        expect(word1.content).not_to be_nil
      end

      it "renders the edit template" do
        expect(response).to render_template(:edit)
      end

      it "returns unprocessable_entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when word does not exist" do
      before { patch :update, params: { id: -1, word: { content: "test" } } }

      it "redirects to index" do
        expect(response).to redirect_to(admin_words_path)
      end

      it "sets a flash message" do
        expect(flash[:danger]).to eq(I18n.t("not_found"))
      end
    end

    context "with unauthorized params" do
      let(:unauthorized_params) { { id: word1.id, word: { content: "updated_content", unauthorized_param: "malicious" } } }

      it "updates the word in the database" do
        patch :update, params: unauthorized_params
        word1.reload
        expect(word1.content).to eq("updated_content")
      end

      it "does not update the word with unauthorized params" do
        patch :update, params: unauthorized_params
        word1.reload
        expect(word1).not_to respond_to(:unauthorized_param)
      end

      it "sets a flash message" do
        patch :update, params: unauthorized_params
        expect(flash[:success]).to eq(I18n.t("admin.words.update.success"))
      end

      it "redirects to the index page" do
        patch :update, params: unauthorized_params
        expect(response).to redirect_to(admin_words_path)
      end
    end
  end

  # Test cho action destroy
  describe "DELETE #destroy" do
    context "when destroy is successful" do
      it "destroys the requested word" do
        expect { delete :destroy, params: { id: word1.id } }.to change(Word, :count).by(-1)
      end

      it "sets a success flash message" do
        delete :destroy, params: { id: word1.id }
        expect(flash[:success]).to eq(I18n.t("admin.words.destroy.success", word_content: word1.content))
      end

      it "redirects to the index page" do
        delete :destroy, params: { id: word1.id }
        expect(response).to redirect_to(admin_words_path)
      end
    end

    context "when destroy fails" do
      let(:word_mock) { instance_double(Word, content: "mock_word") }

      before do
        allow(Word).to receive(:find_by).and_return(word_mock)
        allow(word_mock).to receive(:destroy).and_return(false)
        delete :destroy, params: { id: word1.id }
      end

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("admin.words.destroy.failure", word_content: "mock_word"))
      end
      it "redirects to index" do
        expect(response).to redirect_to(admin_words_path)
      end
    end

    context "when word does not exist" do
      before { delete :destroy, params: { id: -1 } }

      it "redirects to index" do
        expect(response).to redirect_to(admin_words_path)
      end
      it "sets a flash message" do
        expect(flash[:danger]).to eq(I18n.t("not_found"))
      end
    end
  end

  describe "before_action :set_word" do
    context "when word exists" do
      it "assigns the word to @word" do
        get :edit, params: { id: word1.id }
        expect(assigns(:word)).to eq(word1)
      end
    end

    context "when word does not exist" do
      before { get :edit, params: { id: -1 } }

      it "sets a danger flash message" do
        expect(flash[:danger]).to eq(I18n.t("not_found"))
      end

      it "redirects to the admin words path" do
        expect(response).to redirect_to(admin_words_path)
      end
    end
  end
end
