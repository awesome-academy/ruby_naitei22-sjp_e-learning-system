require "rails_helper"

RSpec.describe Api::V1::TestsController, type: :controller do
  let!(:test1) { create(:test, name: "Sample Test 1") }
  let!(:test2) { create(:test, name: "Another Test") }
  let!(:test3) { create(:test, name: "Sample Test 2") }

  describe "GET #search" do
    context "with a valid query param" do
      before { get :search, params: { query: "Sample" } }

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns tests matching the query" do
        expected_tests = [
          { "id" => test1.id, "name" => test1.name },
          { "id" => test3.id, "name" => test3.name }
        ]
        expect(JSON.parse(response.body)).to match_array(expected_tests)
      end
    end

    context "without a query param" do
      before { get :search, params: { query: "" } }

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns all tests" do
        expected_tests = Test.all.map { |test| { "id" => test.id, "name" => test.name } }
        expect(JSON.parse(response.body)).to match_array(expected_tests)
      end
    end

    context "with a query that does not match any tests" do
      before { get :search, params: { query: "Nonexistent" } }

      it "returns a successful response" do
        expect(response).to be_successful
      end

      it "returns an empty array" do
        expect(JSON.parse(response.body)).to be_empty
      end
    end

    context "when there are more than 10 tests" do
      let!(:extra_tests) { 11.times.map { create(:test, name: "Limit Test") } }
      before { get :search, params: { query: "Limit" } }

      it "returns at most 10 tests" do
        expect(JSON.parse(response.body).count).to be <= 10
      end
      it "returns a successful response" do
        expect(response).to be_successful
      end
    end
  end
end
