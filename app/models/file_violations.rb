# Find violations in file
class FileViolations
  include Enumerable

  def initialize(filename)
    @filename = filename
    @violations = {}
  end

  def add(line, message)
    if @violations[line.number].nil?
      violation = Violation.new(@filename, line, [message])
      @violations[line.number] = violation
    else
      @violations[line.number].add_message(message)
    end
  end

  def each &block
    @violations.each do |line_number, violation|
      yield violation
    end
  end
end
