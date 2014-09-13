# Hold file, line, and violation message values.
# Built by style guides.
# Printed by Commenter.
class Violation
  attr_initialize :filename, :line, :messages

  def patch_position
    @line.patch_position
  end

  def add_message(message)
    @messages << message
  end

  def messages
    @messages.uniq
  end
end
