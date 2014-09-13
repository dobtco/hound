require "fast_spec_helper"
require "app/models/violation"
require "app/models/file_violations"

describe FileViolations do
  describe "#add" do
    context "when collection is empty" do
      it "adds new violation" do
        line = double("Line", number: 2, patch_position: 1)
        violations = FileViolations.new("foo.rb")

        violations.add(line, "hello world")

        expect(violations.count).to eq 1
        expect(violations.first.patch_position).to eq(line.patch_position)
        expect(violations.first.messages).to eq(["hello world"])
      end
    end

    context "when violation already exists on the same line" do
      it "adds message to the violation" do
        line = double("Line", number: 2, patch_position: 3)
        violations = FileViolations.new("foo.rb")

        violations.add(line, "message 1")
        violations.add(line, "message 2")

        expect(violations.count).to eq 1
        expect(violations.first.messages).to eq(["message 1", "message 2"])
      end
    end
  end
end
