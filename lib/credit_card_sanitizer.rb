require 'luhn_checksum'

class CreditCardSanitizer

  NUMBERS_WITH_LINE_NOISE = /(
    \d       # starts with a number
    [\d|\W]+ # number or non-word character
    \d       # ends with a number
  )/x

  def self.parameter_filter
    Proc.new { |_, value| new.sanitize!(value) if value.is_a?(String) }
  end

  def initialize(replacement_token = 'X', replace_first = 6, replace_last = 4)
    @replacement_token, @replace_first, @replace_last = replacement_token, replace_first, replace_last
  end

  def sanitize!(text)
    replaced = nil

    text.gsub!(NUMBERS_WITH_LINE_NOISE) do |match|
      numbers = match.gsub(/\D/, '')
      size = numbers.size

      if size.between?(13, 19) && LuhnChecksum.valid?(numbers)
        replaced = true
        replace_numbers!(match, size - @replace_last)
      end

      match
    end

    replaced && text
  end

  def replace_numbers!(text, replacement_limit)
    # Leave the first @replace_first and last @replace_last numbers visible
    digit_index = 0

    text.gsub!(/\d/) do |number|
      digit_index += 1
      if digit_index > @replace_first && digit_index <= replacement_limit
        @replacement_token
      else
        number
      end
    end
  end
end
