require "rails_helper"

RSpec.describe Component, type: :model do
  # Test Enum
  describe "enum" do
    it "has a valid component_type enum" do
      expect(Component.component_types.keys).to match_array(["word", "test", "paragraph"])
    end
  end

  # Test Scopes
  describe "scopes" do
    let!(:lesson) { create(:lesson) }
    let!(:component1) { create(:component, lesson: lesson, index_in_lesson: 2) }
    let!(:component2) { create(:component, lesson: lesson, index_in_lesson: 1) }
    let!(:component3) { create(:component, lesson: lesson, index_in_lesson: 3) }

    describe ".sorted_by_index" do
      it "returns components sorted by index_in_lesson in ascending order" do
        expect(Component.sorted_by_index).to eq([component2, component1, component3])
      end
    end
  end
end
