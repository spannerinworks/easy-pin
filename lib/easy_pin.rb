module EasyPin
  # removes m, n because they be easily misunderstood when speaking
  # removes i, s, 1, 5, o, 0 because they can be easily misread
  # removes a, e, f, u to avoid swear words being generated
  EASY_PUBLIC = 'bcdghjkpqrtvwxyz2346789'.chars

  NUMERIC = '0123456789'.chars

  class Generator

    def self.build(dictionary: EASY_PUBLIC, random_seed: 24, padding: 4, separator: '')
      Generator.new(base_converter: BaseConverter.new(dictionary.size),
                    checksum_generator: ChecksumGenerator.new(dictionary.size),
                    tumbler: Tumbler.new(dictionary, Random.new(random_seed)),
                    padder: Padder.new(padding),
                    formatter: Formatter.new(separator))
    end

    def initialize(base_converter:, checksum_generator:, tumbler:, padder:, formatter:)
      @base_converter = base_converter
      @checksum_generator = checksum_generator
      @tumbler = tumbler
      @padder = padder
      @formatter = formatter
    end

    def generate(integer)
      integer = integer.to_i

      raise InvalidInput, 'input must be an integer >= 1' unless integer >= 1

      parts = @base_converter.convert(integer)

      parts = @checksum_generator.checksum(parts)

      parts = @padder.pad(parts)

      parts = @tumbler.tumble(parts)

      @formatter.format(parts)
    end

    def revert(code)
      parts = @formatter.unformat(code)

      parts = @tumbler.untumble(parts)

      parts = @padder.unpad(parts)

      parts = @checksum_generator.unchecksum(parts)

      @base_converter.unconvert(parts)
    end

  end

  class InvalidInput < StandardError; end

  class BaseConverter
    def initialize(base)
      @base = base
    end

    def convert(integer)
      parts = []

      while integer > 0
        parts.unshift(integer % @base)
        integer = integer / @base
      end

      parts
    end

    def unconvert(parts)
      sum = 0

      parts.reverse.each_with_index do |part, index|
        sum += part * (@base ** index)
      end

      sum
    end
  end

  class InvalidChecksum < StandardError; end

  class ChecksumGenerator
    def initialize(base)
      @base = base
    end

    def checksum(parts)
      parts + [sum(parts)]
    end

    def unchecksum(parts)
      validate(parts)
      parts[0..-2]
    end

    def validate(parts)
      checksum = sum(parts[0..-2])
      expected = parts[-1]
      raise InvalidChecksum, "invalid checksum #{checksum}, expected #{expected}" if checksum != expected
    end

    private def sum(parts)
      parts.inject(:+) % @base
    end
  end

  class Padder
    def initialize(amount)
      @amount = amount
    end

    def pad(parts)
      padding_parts = [0] * [@amount - parts.size, 0].max

      padding_parts + parts
    end

    def unpad(parts)
      if parts[0].zero?
        unpad(parts[1..-1])
      else
        parts
      end
    end

  end

  class Tumbler
    def initialize(dictionary, random, max_width = 32)
      @shuffle = (0..max_width-1).map{ dictionary.shuffle(random: random) }
      @unshuffle = @shuffle.map{ |dict| Hash[dict.each_with_index.map{|a,b| [a,b]}] }
    end

    def tumble(parts)
      validate parts
      res = []
      parts.each_with_index{|part, index| res << @shuffle.fetch(index).fetch(part)}
      res
    end

    def untumble(parts)
      validate parts
      res = []
      parts.each_with_index{|part, index| res << @unshuffle.fetch(index).fetch(part)}
      res
    end

    def validate(parts)
      raise InvalidInput, 'input has too many values' unless parts.length < @shuffle.length

      parts.each_with_index do |part, index|
        case part
        when Numeric
          max = @shuffle.fetch(index).length - 1
          raise InvalidInput, "#{part} is not within #{0} and #{max}" unless part <= max && part >= 0
        when String
          raise InvalidInput, "'#{part}' is not a valid value" unless @unshuffle.fetch(index).key?(part)
        else
          raise InvalidInput, "#{part.class} is not a valid input type"
        end
      end
    end
  end

  class Formatter
    def initialize(separator)
      @separator = separator
    end

    def format(parts)
      parts.join(@separator)
    end

    def unformat(code)
      code.split(@separator)
    end
  end

end
