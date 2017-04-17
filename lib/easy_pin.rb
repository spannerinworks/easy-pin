class EasyPin
  # removes m, n because they be easily misunderstood when speakind
  # removes i, s, 1, 5, o, 0 because they can be easily misread
  # removes a, e, f, u to avoid swear words being generated
  EASY_PUBLIC = 'bcdghjkpqrtvwxyz2346789'

  NUMERIC = '0123456789'

  class Generator

    def self.build(charset: EASY_PUBLIC, random_seed: 24, padding: 4)
      Generator.new(base_converter: BaseConverter.new(charset.size),
                    checksum_generator: ChecksumGenerator.new(charset.size),
                    tumbler: Tumbler.new(charset, Random.new(random_seed)),
                    padding: padding)
    end

    def initialize(base_converter:, checksum_generator:, tumbler:, padding:)
      @base_converter = base_converter
      @checksum_generator = checksum_generator
      @tumbler = tumbler
      @padding = padding
    end


    def generate(integer)
      parts = @base_converter.convert(integer)

      parts << @checksum_generator.checksum(parts)

      padding_parts = [0] * [@padding - parts.size, 0].max

      code = padding_parts + parts

      @tumbler.tumble(code).join
    end

  end

  class BaseConverter
    def initialize(base)
      @base = base
    end

    def convert(integer)
      parts = []

      while @base ** parts.length <= integer
        parts << (integer / (@base ** parts.length)) % @base
      end

      parts
    end
  end

  class ChecksumGenerator
    def initialize(base)
      @base = base
    end

    def checksum(parts)
      parts.inject(0) { |acc, part| acc + (part % 2) } % @base
    end
  end

  class Tumbler
    def initialize(charset, random, max_width = 32)
      @shuffle = (0..max_width-1).map{ charset.chars.shuffle(random: random) }
    end

    def tumble(parts)
      res = []
      parts.each_with_index{|part, index| res << @shuffle[index][part]}
      res
    end
  end

end
