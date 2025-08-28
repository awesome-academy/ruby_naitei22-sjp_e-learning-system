require "rails_helper"

RSpec.describe Api::V1::WordsController, type: :controller do
  let!(:word1) { create(:word, content: "apple") }
  let!(:word2) { create(:word, content: "banana") }
  let!(:word3) { create(:word, content: "pineapple") }

  describe "GET #search" do
    context "with a valid query param" do
      before { get :search, params: { query: "apple" } }

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns words matching the query" do
        expected_words = [
          { "id" => word1.id, "content" => word1.content },
          { "id" => word3.id, "content" => word3.content }
        ]
        expect(JSON.parse(response.body)).to match_array(expected_words)
      end
    end

    context "without a query param" do
      it "returns a successful response" do
        get :search, params: { query: "" }
        expect(response).to be_successful
      end

      it "returns all words" do
        get :search, params: { query: "" }
        expected_words = Word.all.map { |word| { "id" => word.id, "content" => word.content } }
        expect(JSON.parse(response.body)).to match_array(expected_words)
      end
    end

    context "with a query that does not match any words" do
      it "returns a successful response" do
        get :search, params: { query: "Nonexistent" }
        expect(response).to be_successful
      end

      it "returns an empty array" do
        get :search, params: { query: "Nonexistent" }
        expect(JSON.parse(response.body)).to be_empty
      end
    end
  end
end
