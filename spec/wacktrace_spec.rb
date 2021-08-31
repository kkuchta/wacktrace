# frozen_string_literal: true

RSpec.describe Wacktrace do
  describe 'add_to_stack' do
    let(:lines) {
      [
        ["somemethod1", 111, "somefile1"],
        ["somemethod2", 222, "somefile2"],
        ["somemethod3", 333, "somefile3"],
      ]
    }
    let(:real_return_value) { 3 }
    let(:real) { proc {
      @caller_locations = caller_locations.map(&:to_s)
      real_return_value
    } }
    subject { described_class.add_to_stack(lines, &real) }

    it "adds lines to the stack trace" do
      subject
      expect(@caller_locations[1, 3]).to eq [
        "somefile3:333:in ` somemethod3'",
        "somefile2:222:in ` somemethod2'",
        "somefile1:111:in ` somemethod1'",
      ]
    end

    it "still calls the underlying block" do
      expect(subject).to eq real_return_value
    end

    context 'with no lines' do
      let(:lines) { [] }
      it "still calls the underlying block" do
        expect(subject).to eq real_return_value
      end
    end
    context 'with only one line' do
      let(:lines) {
        [["somemethod1", 111, "somefile1"]]
      }
      it "adds line to the stack trace" do
        subject
        expect(@caller_locations[1, 1]).to eq [
          "somefile1:111:in ` somemethod1'",
        ]
      end
      it "still calls the underlying block" do
        expect(subject).to eq real_return_value
      end
    end

    context 'with duplicate method names' do
      let(:lines) {[
        ["somemethod1", 123, "somefile1"],
        ["somemethod2", 123, "somefile2"],
        ["somemethod1", 123, "somefile1"],
      ]}

      it "includes all lines in stack trace" do
        subject
        expect(@caller_locations[1, 3]).to eq [
          "somefile1:123:in ` somemethod1 '",
          "somefile2:123:in ` somemethod2'",
          "somefile1:123:in ` somemethod1'",
        ]
      end

      context 'with many duplicates' do
        let(:lines) {[
          ["somemethod1", 123, "somefile1"],
          ["somemethod1", 123, "somefile1"],
          ["somemethod1", 123, "somefile1"],
          ["somemethod1", 123, "somefile1"],
        ]}
        it "includes all lines with increasing non-breaking spaces" do
          subject
          expect(@caller_locations[1, 4]).to eq [
            "somefile1:123:in ` somemethod1   '",
            "somefile1:123:in ` somemethod1  '",
            "somefile1:123:in ` somemethod1 '",
            "somefile1:123:in ` somemethod1'",
          ]
        end
      end
    end
  end

  describe 'add_to_stack_from_lyrics' do
    let(:real_return_value) { 3 }
    let(:real) { proc {
      @caller_locations = caller_locations.map(&:to_s)
      real_return_value
    } }
    let(:lyrics) { "
row row row your boat
gently down the stream
    ".strip }
    let(:filename) { "whatever" }
    subject { described_class.add_to_stack_from_lyrics(lyrics, filename, &real) }
    it "constructs lines and passes them to add_to_stack" do
      expect(described_class).to receive(:add_to_stack).with(
        [
          ["row row row your boat", 0, filename],
          ["gently down the stream", 1, filename]
        ]
      )
      subject
    end
  end
end
