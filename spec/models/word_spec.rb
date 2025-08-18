require "rails_helper"

RSpec.describe Word, type: :model do
  # Section: Test Validations
  describe "validations" do
    let(:valid_attributes) do
      {
        content: "hello",
        meaning: "a greeting",
        word_type: :noun
      }
    end

    it "is valid with a content, meaning, and word_type" do
      word = Word.new(valid_attributes)
      expect(word).to be_valid
    end

    it "is not valid without content" do
      word = Word.new(valid_attributes.merge(content: nil))
      expect(word).not_to be_valid
    end

    it "includes a content error when content is missing" do
      word = Word.new(valid_attributes.merge(content: nil))
      word.valid?
      expect(word.errors[:content]).to include(I18n.t("errors.messages.blank"))
    end

    it "is not valid without meaning" do
      word = Word.new(valid_attributes.merge(meaning: nil))
      expect(word).not_to be_valid
    end

    it "includes a meaning error when meaning is missing" do
      word = Word.new(valid_attributes.merge(meaning: nil))
      word.valid?
      expect(word.errors[:meaning]).to include(I18n.t("errors.messages.blank"))
    end

    it "is not valid without word_type" do
      word = Word.new(valid_attributes.merge(word_type: nil))
      expect(word).not_to be_valid
    end

    it "includes a word_type error when word_type is missing" do
      word = Word.new(valid_attributes.merge(word_type: nil))
      word.valid?
      expect(word.errors[:word_type]).to include(I18n.t("errors.messages.blank"))
    end

    it "raises an ArgumentError with an invalid word_type" do
      expect {
        Word.new(valid_attributes.merge(word_type: "invalid_type"))
      }.to raise_error(ArgumentError, "'invalid_type' is not a valid word_type")
    end
  end

  # Section: Test Associations
  describe "associations" do
    it "destroys associated components when the word is deleted" do
      word = create(:word)
      lesson = create(:lesson)
      component = Component.create!(
        lesson: lesson,
        component_type: :word,
        word: word,
        index_in_lesson: 1
      )

      expect { word.destroy }.to change { Component.count }.by(-1)
    end
  end

  # Section: Test Scopes
  describe "scopes" do
    let!(:word1) { create(:word, content: "apple", created_at: Time.zone.now.beginning_of_day, word_type: :noun) }
    let!(:word2) { create(:word, content: "banana", created_at: 1.day.ago, word_type: :verb) }
    let!(:word3) { create(:word, content: "orange", created_at: 7.days.ago, word_type: :adjective) }
    let!(:word4) { create(:word, content: "apricot", created_at: 31.days.ago, word_type: :noun) }

    describe ".by_type" do
      it "returns words of a specific type" do
        expect(Word.by_type(:noun)).to match_array([word1, word4])
      end
    end

    describe ".recent" do
      it "returns words in descending order of creation date" do
        expect(Word.recent).to eq([word1, word2, word3, word4])
      end
    end

    describe ".by_content" do
      context "with a query" do
        it "returns words whose content includes the query" do
          expect(Word.by_content("a")).to match_array([word1, word2, word3, word4])
        end

        it "finds a single word by a partial content query" do
          expect(Word.by_content("app")).to eq([word1])
        end

        it "returns an empty array when no words match the query" do
          expect(Word.by_content("xyz")).to be_empty
        end
      end

      context "without a query" do
        it "returns all words" do
          expect(Word.by_content(nil)).to match_array([word1, word2, word3, word4])
        end
      end
    end

    describe ".by_time" do
      context "with 'today' filter" do
        it "returns words created today" do
          expect(Word.by_time(Settings.filter_days.today)).to eq([word1])
        end
      end

      context "with 'last_7_days' filter" do
        it "returns words created in the last 7 days" do
          expect(Word.by_time(Settings.filter_days.last_7_days)).to match_array([word1, word2, word3])
        end
      end

      context "with 'last_30_days' filter" do
        it "returns words created in the last 30 days" do
          expect(Word.by_time(Settings.filter_days.last_30_days)).to match_array([word1, word2, word3])
        end
      end

      context "with an invalid filter" do
        it "returns all words" do
          expect(Word.by_time("invalid_filter")).to match_array([word1, word2, word3, word4])
        end
      end

      context "without a filter" do
        it "returns all words" do
          expect(Word.by_time(nil)).to match_array([word1, word2, word3, word4])
        end
      end
    end

    describe ".search" do
      context "with a query and no field" do
        it "searches content and meaning" do
          word1.update(meaning: "fruit is good")
          expect(Word.search("fruit")).to eq([word1])
        end
      end

      context "with a query and content field" do
        it "searches content only" do
          expect(Word.search("apple", "content")).to eq([word1])
        end
      end

      context "with a query and meaning field" do
        it "searches meaning only" do
          word2.update(meaning: "yellow fruit")
          expect(Word.search("yellow", "meaning")).to eq([word2])
        end
      end

      context "without a query" do
        it "returns all words" do
          expect(Word.search(nil)).to match_array([word1, word2, word3, word4])
        end
      end
    end

    describe ".filter_by_type" do
      context "with a type filter" do
        it "returns words of that type" do
          expect(Word.filter_by_type("noun")).to match_array([word1, word4])
        end
      end

      context "with 'all' filter" do
        it "returns all words" do
          expect(Word.filter_by_type("all")).to match_array([word1, word2, word3, word4])
        end
      end

      context "without a type filter" do
        it "returns all words" do
          expect(Word.filter_by_type(nil)).to match_array([word1, word2, word3, word4])
        end
      end
    end

    describe ".sorted" do
      it "sorts alphabetically ascending by default" do
        expect(Word.sorted(nil)).to eq([word1, word4, word2, word3])
      end

      it "sorts by alphabetical descending" do
        expect(Word.sorted(:alphabetical_desc)).to eq([word3, word2, word4, word1])
      end

      it "sorts by newest" do
        expect(Word.sorted(:newest)).to eq([word1, word2, word3, word4])
      end

      it "sorts by oldest" do
        expect(Word.sorted(:oldest)).to eq([word4, word3, word2, word1])
      end

      it "sorts by word_type and then content" do
        expect(Word.sorted(:word_type)).to eq([word1, word4, word2, word3])
      end
    end

    describe ".learned_word_ids_for" do
      let(:user) { create(:user) }
      let!(:word_a) { create(:word) }
      let!(:word_b) { create(:word) }
      let(:lesson) { create(:lesson) }

      before do
        component1 = Component.create!(lesson: lesson, component_type: :word, word: word_a, index_in_lesson: 1)
        component2 = Component.create!(lesson: lesson, component_type: :word, word: word_b, index_in_lesson: 2)
        component3 = Component.create!(lesson: lesson, component_type: :word, word: word_a, index_in_lesson: 3)

        UserWord.create!(user: user, component: component1)
        UserWord.create!(user: user, component: component2)
        UserWord.create!(user: user, component: component3)
      end

      it "returns unique IDs of learned words for a user" do
        expect(Word.learned_word_ids_for(user)).to match_array([word_a.id, word_b.id])
      end

      it "returns an empty array if the user has not learned any words" do
        new_user = create(:user)
        expect(Word.learned_word_ids_for(new_user)).to be_empty
      end
    end

    describe ".filter_by_status" do
      let(:user) { create(:user) }
      let!(:learned_word) { create(:word) }
      let!(:unlearned_word) { create(:word) }

      before do
        component = create(:word_component, word: learned_word)
        create(:user_word, user: user, component: component)
      end

      context "when status is 'learned'" do
        it "returns only learned words" do
          expect(Word.filter_by_status(:learned, user)).to eq([learned_word])
        end
      end

      context "when status is 'not_learned'" do
        it "returns all words that are not learned" do
          expect(Word.filter_by_status(:not_learned, user)).to match_array([unlearned_word, word1, word2, word3, word4])
        end
      end

      context "when status is blank" do
        it "returns all words" do
          expect(Word.filter_by_status(nil, user)).to match_array([learned_word, unlearned_word, word1, word2, word3, word4])
        end
      end

      context "when status is invalid" do
        it "returns all words" do
          expect(Word.filter_by_status(:invalid_status, user)).to match_array([learned_word, unlearned_word, word1, word2, word3, word4])
        end
      end
    end
  end

  # Section: Test Instance Methods
  describe "#learned_by?" do
    let(:user) { create(:user) }
    let(:word) { create(:word) }

    context "when the word is learned by the user" do
      before do
        component = create(:word_component, word: word)
        create(:user_word, user: user, component: component)
      end

      it "returns true" do
        expect(word.learned_by?(user)).to be_truthy
      end
    end

    context "when the word is not learned by the user" do
      it "returns false" do
        expect(word.learned_by?(user)).to be_falsey
      end
    end
  end
end
