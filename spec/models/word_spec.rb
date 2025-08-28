require "rails_helper"

RSpec.describe Word, type: :model do
  let!(:user) { create(:user) }
  let!(:word_learned) { create(:word, word_type: :noun) }
  let!(:word_not_learned) { create(:word, word_type: :verb) }
  let!(:component) { create(:component, word: word_learned) }
  let!(:user_word) { create(:user_word, user: user, component: component) }
  let(:word) { create(:word) }

  # Test Validations
  describe "validations" do
    it "is valid with all required attributes" do
      expect(word).to be_valid
    end

    it "is invalid without content" do
      word.content = nil
      expect(word).not_to be_valid
    end

    it "is invalid without meaning" do
      word.meaning = nil
      expect(word).not_to be_valid
    end

    it "is invalid without a word_type" do
      word.word_type = nil
      expect(word).not_to be_valid
    end

    it "raises error with an undefined word_type" do
      expect { word.word_type = :invalid_type }.to raise_error(ArgumentError)
    end
  end

  # Test Associations
  describe "associations" do
    it "destroys its components when destroyed" do
      word = create(:word)
      create_list(:component, 3, word: word)
      expect { word.destroy }.to change(Component, :count).by(-3)
    end
  end

  # Test Scopes
  describe "scopes" do
    let!(:old_word)  { create(:word, created_at: 10.days.ago) }
    let!(:noun_word) { create(:word, content: "test noun", word_type: :noun) }
    let!(:verb_word) { create(:word, content: "test verb",  word_type: :verb) }
    let!(:new_word)  { create(:word, created_at: Time.zone.now) }

    describe ".by_type" do
      it "returns words with the given type" do
        expect(Word.by_type(:noun)).to include(noun_word)
      end

      it "excludes words of different types" do
        expect(Word.by_type(:noun)).not_to include(verb_word)
      end
    end

    describe ".recent" do
      it "orders by most recent first" do
        expect(Word.recent.first).to eq(new_word)
      end

      it "orders by oldest last" do
        expect(Word.recent.last).to eq(old_word)
      end
    end

    describe ".by_content" do
      it "returns words matching the query" do
        expect(Word.by_content("noun")).to include(noun_word)
      end

      it "excludes words not matching the query" do
        expect(Word.by_content("noun")).not_to include(verb_word)
      end

      it "returns all words when query is blank" do
        # một expect, matcher kiểm tra 2 phần tử
        expect(Word.by_content("")).to include(noun_word, verb_word)
      end
    end

    describe ".by_time" do
      context "when filter_time is today" do
        it "includes words created today" do
          expect(Word.by_time(Settings.filter_days.today)).to include(new_word)
        end

        it "excludes words not created today" do
          expect(Word.by_time(Settings.filter_days.today)).not_to include(old_word)
        end
      end

      context "when filter_time is last_7_days" do
        let!(:word_in_7_days) { create(:word, created_at: 6.days.ago) }

        it "includes words created within the last 7 days" do
          expect(Word.by_time(Settings.filter_days.last_7_days)).to include(word_in_7_days, new_word)
        end

        it "excludes words created before last 7 days" do
          expect(Word.by_time(Settings.filter_days.last_7_days)).not_to include(old_word)
        end
      end

      context "when filter_time is last_30_days" do
        let!(:word_in_30_days) { create(:word, created_at: 20.days.ago) }

        it "includes words created within the last 30 days" do
          expect(Word.by_time(Settings.filter_days.last_30_days)).to include(word_in_30_days, new_word)
        end

        it "excludes words created before last 30 days" do
          very_old = create(:word, created_at: 40.days.ago)
          expect(Word.by_time(Settings.filter_days.last_30_days)).not_to include(very_old)
        end
      end

      context "when filter_time is invalid" do
        it "returns all words" do
          result = Word.by_time(:invalid_value)
          expect(result).to match_array(Word.all)
        end
      end
    end


    describe ".filter_by_status" do
      context "when status is learned" do
        it "includes learned words" do
          expect(Word.filter_by_status(:learned, user)).to include(word_learned)
        end

        it "excludes not learned words" do
          expect(Word.filter_by_status(:learned, user)).not_to include(word_not_learned)
        end
      end

      context "when status is not_learned" do
        it "includes not learned words" do
          expect(Word.filter_by_status(:not_learned, user)).to include(word_not_learned)
        end

        it "excludes learned words" do
          expect(Word.filter_by_status(:not_learned, user)).not_to include(word_learned)
        end
      end

      context "when status is blank" do
        it "returns all words" do
          result = Word.filter_by_status(nil, user)
          expect(result).to match_array(Word.all)
        end
      end

      context "when status is invalid" do
        it "returns all words" do
          result = Word.filter_by_status(:invalid_status, user)
          expect(result).to match_array(Word.all)
        end
      end
    end
  end

  # Test Instance and Class Methods
  describe "methods" do
    describe ".learned_word_ids_for" do
      it "returns IDs of words learned by the user" do
        expect(Word.learned_word_ids_for(user)).to eq([word_learned.id])
      end
    end

    describe "#learned_by?" do
      it "returns true if the user learned the word" do
        expect(word_learned.learned_by?(user)).to be true
      end

      it "returns false if the user has not learned the word" do
        expect(word_not_learned.learned_by?(user)).to be false
      end
    end
  end

  describe "ransack configuration" do
    describe ".ransackable_attributes" do
      it "returns only allowed attributes" do
        expect(Word.ransackable_attributes).to match_array(
          %w(content meaning word_type_key created_at updated_at)
        )
      end
    end

    describe ".ransackable_associations" do
      it "returns empty array" do
        expect(Word.ransackable_associations).to eq([])
      end
    end

    describe "ransacker :word_type_key" do
      let!(:noun_word) { create(:word, word_type: :noun) }
      let!(:verb_word) { create(:word, word_type: :verb) }

      it "allows search by word_type_key = 'noun'" do
        result = Word.ransack(word_type_key_eq: "noun").result
        expect(result).to include(noun_word)
      end

      it "does not include words of other type when searching 'noun'" do
        result = Word.ransack(word_type_key_eq: "noun").result
        expect(result).not_to include(verb_word)
      end

      it "allows search by word_type_key = 'verb'" do
        result = Word.ransack(word_type_key_eq: "verb").result
        expect(result).to include(verb_word)
      end
    end
  end
end
