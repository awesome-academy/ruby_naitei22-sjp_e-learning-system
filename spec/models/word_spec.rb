require "rails_helper"

RSpec.describe Word, type: :model do
  # --- Setup Dữ liệu ---
  let(:user) { create(:user) }
  let(:word) { create(:word) }

  # --- Test Validations ---
  describe "Validations" do
    it "is valid with valid attributes" do
      expect(word).to be_valid
    end

    it "is invalid without content" do
      word.content = nil
      expect(word).not_to be_valid
    end

    it "is invalid without a meaning" do
      word.meaning = nil
      expect(word).not_to be_valid
    end

    it "is invalid without a word_type" do
      word.word_type = nil
      expect(word).not_to be_valid
    end

    it "is invalid with a non-existent word_type" do
      expect {
        build(:word, word_type: :invalid_type)
      }.to raise_error(ArgumentError)
    end
  end

  # --- Test Associations ---
  describe "Associations" do
    it "has many components" do
      association = described_class.reflect_on_association(:components)
      expect(association.macro).to eq :has_many
    end
  end

  # --- Test Enums ---
  describe "Enums" do
    it "defines the correct enum for word_type" do
      expect(described_class.word_types).to include("noun", "verb", "adjective")
    end
  end

  # --- Test Scopes ---
  describe "Scopes" do
    let!(:noun_word) { create(:word, word_type: :noun, created_at: 1.day.ago) }
    let!(:verb_word) { create(:word, word_type: :verb, created_at: Time.current) }
    let!(:adjective_word) { create(:word, word_type: :adjective, created_at: 8.days.ago) }

    context "scope: by_type" do
      it "returns only words of the specified type" do
        expect(Word.by_type(:noun)).to contain_exactly(noun_word)
      end
    end

    context "scope: recent" do
      it "orders words by most recently created" do
        expect(Word.recent.first).to eq(verb_word)
      end
    end

    context "scope: by_content" do
      let!(:searchable_word) { create(:word, content: "apple pie") }

      it "returns words matching the content query" do
        expect(Word.by_content("apple")).to include(searchable_word)
      end

      it "returns all words if query is blank" do
        expect(Word.by_content("").count).to eq(4)
      end
    end

    context "scope: by_time" do
      it "returns words created today for 'today' filter" do
        expect(Word.by_time("today")).to contain_exactly(verb_word)
      end

      it "returns words created in the last 7 days for 'last_7_days' filter" do
        expect(Word.by_time("last_7_days")).to contain_exactly(verb_word, noun_word)
      end

      it "returns all words for an invalid filter" do
        expect(Word.by_time("invalid_filter").count).to eq(3)
      end
    end

    context "scope: filter_by_status" do
      let!(:learned_word) { create(:word) }
      let!(:not_learned_word) { create(:word) }
      let!(:user_word) { create(:user_word, user: user, component: create(:component, word: learned_word)) }

      it "returns only learned words for 'learned' status" do
        expect(Word.filter_by_status(:learned, user)).to contain_exactly(learned_word)
      end

      it "returns only words that have not been learned for 'not_learned' status" do
        expect(Word.filter_by_status(:not_learned, user)).not_to include(learned_word)
      end

      it "returns all words if status is blank" do
        expect(Word.filter_by_status("", user).count).to eq(Word.count)
      end

      it "returns all words for an invalid status" do
        expect(Word.filter_by_status(:invalid_status, user).count).to eq(Word.count)
      end
    end
  end

  # --- Test Class Methods ---
  describe "Class Methods" do
    # THÊM MỚI: Test case cho các phương thức ransackable
    context ".ransackable_attributes" do
      it "returns the correct array of attributes" do
        attributes = %w(content meaning word_type created_at)
        expect(Word.ransackable_attributes).to eq(attributes)
      end
    end

    context ".ransackable_associations" do
      it "returns the correct array of associations" do
        associations = %w(components)
        expect(Word.ransackable_associations).to eq(associations)
      end
    end

    context ".ransackable_scopes" do
      it "returns the correct array of scopes" do
        scopes = [:by_time]
        expect(Word.ransackable_scopes).to eq(scopes)
      end
    end

    context ".learned_word_ids_for" do
      let!(:learned_word) { create(:word) }
      let!(:component) { create(:component, word: learned_word) }
      let!(:user_word) { create(:user_word, user: user, component: component) }

      it "returns an array of word IDs learned by the user" do
        expect(Word.learned_word_ids_for(user)).to eq([learned_word.id])
      end
    end
  end

  # --- Test Instance Methods ---
  describe "#learned_by?" do
    let!(:learned_word) { create(:word) }
    let!(:not_learned_word) { create(:word) }
    let!(:component) { create(:component, word: learned_word) }
    let!(:user_word) { create(:user_word, user: user, component: component) }

    it "returns true if the user has learned the word" do
      expect(learned_word.learned_by?(user)).to be true
    end

    it "returns false if the user has not learned the word" do
      expect(not_learned_word.learned_by?(user)).to be false
    end
  end
end
