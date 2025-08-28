# frozen_string_literal: true
require "rails_helper"

RSpec.describe Admin::WordsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:admin)  { create(:user, :admin) }
  let(:user)   { create(:user) }
  let(:limit)  { 5 }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in admin
    allow(Settings).to receive_message_chain(:word, :pagy_items).and_return(limit)
  end

  describe "GET #index" do
    context "page=1 without filters" do
      let!(:words) do
        (limit + 3).times.map do |i|
          create(:word, created_at: i.minutes.ago)
        end
      end

      it "responds with 200 OK" do
        get :index, params: { page: 1 }
        expect(response).to have_http_status(:ok)
      end

      it "assigns @pagy items equals Settings.word.pagy_items" do
        get :index, params: { page: 1 }
        expect(assigns(:words).size).to eq(limit)
      end

      it "assigns @pagy count equals total words" do
        get :index, params: { page: 1 }
        expect(assigns(:pagy).count).to eq(words.count)
      end

      it "orders by recent (newer first)" do
        get :index, params: { page: 1 }
        page_ids = assigns(:words).map(&:id)
        newest = Word.order(created_at: :desc).limit(limit).pluck(:id)
        expect(page_ids).to eq(newest)
      end
    end

    context "with content query filter" do
      let!(:match)     { create(:word, content: "ruby on rails") }
      let!(:not_match) { create(:word, content: "python") }

      it "applies by_content scope" do
        get :index, params: { query: "rails" }
        ids = assigns(:words).pluck(:id)
        expect(ids).to include(match.id)
      end
    end

    context "with time filter" do
      let!(:old_word) { create(:word, created_at: 30.days.ago) }
      let!(:new_word) { create(:word, created_at: 1.day.ago) }

      it "applies by_time scope" do
        get :index, params: { filter_time: "last_7_days" }
        ids = assigns(:words).pluck(:id)
        expect(ids).to include(new_word.id)
      end
    end
  end

  describe "GET #new" do
    it "renders new" do
      get :new
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        word: {
          content: "cancan",
          meaning: "authorization lib",
          word_type: "noun"
        }
      }
    end

    let(:invalid_params) do
      {
        word: {
          content: "",
          meaning: "x",
          word_type: "noun"
        }
      }
    end

    it "creates a word and persisted attributes match params" do
      post :create, params: valid_params
      created = Word.last
      expect(created.slice("content", "meaning", "word_type"))
        .to eq(valid_params[:word].stringify_keys)
    end

    it "redirects with success flash on success" do
      post :create, params: valid_params
      expect(flash[:success]).to eq(I18n.t("admin.words.create.success"))
    end

    it "renders new with 422 on failure" do
      post :create, params: invalid_params
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET #edit" do
    let!(:word) { create(:word) }

    it "renders edit when id found" do
      get :edit, params: { id: word.id }
      expect(response).to have_http_status(:ok)
    end

    it "raises RecordNotFound when id = -1" do
      expect { get :edit, params: { id: -1 } }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "PATCH #update" do
    let!(:word) { create(:word, content: "old") }

    it "updates and persisted data matches params" do
      patch :update, params: { id: word.id, word: { content: "new", meaning: "m", word_type: "noun" } }
      expect(word.reload.content).to eq("new")
    end

    it "redirects with success flash on success" do
      patch :update, params: { id: word.id, word: { content: "new2", meaning: "m", word_type: "noun" } }
      expect(flash[:success]).to eq(I18n.t("admin.words.update.success"))
    end

    it "renders edit with 422 on failure" do
      patch :update, params: { id: word.id, word: { content: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "raises RecordNotFound when id = -1" do
      expect {
        patch :update, params: { id: -1, word: { content: "x" } }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "DELETE #destroy" do
    let!(:word) { create(:word, content: "abc") }

    it "destroys and shows success flash" do
      delete :destroy, params: { id: word.id }
      expect(flash[:success]).to eq(I18n.t("admin.words.destroy.success", word_content: "abc"))
    end

    it "shows danger flash when destroy fails" do
      allow_any_instance_of(Word).to receive(:destroy).and_return(false)
      delete :destroy, params: { id: word.id }
      expect(flash[:danger]).to eq(I18n.t("admin.words.destroy.failure", word_content: "abc"))
    end

    it "raises RecordNotFound when id = -1" do
      expect { delete :destroy, params: { id: -1 } }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "authorization with CanCanCan" do
    let!(:word) { create(:word) }

    context "when user is not admin" do
      before do
        sign_out admin
        sign_in user
      end

      it "forbids index via CanCan (raises AccessDenied)" do
        expect { get :index }.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
