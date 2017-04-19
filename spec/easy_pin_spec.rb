require 'easy_pin'
require 'prime'

RSpec.describe EasyPin do

  it 'generates unique reversable pin codes that are made up of the dictionary' do
    generator = EasyPin::Generator.build

    uniq_hash ||= {}

    Prime.each(100_000) do |prime|
      code = generator.generate(prime)

      expect(generator.revert(code)).to eq prime

      expect(uniq_hash.key?(code)).to eq false

      expect(EasyPin::EASY_PUBLIC).to include(*code.chars.uniq)

      uniq_hash[code] = true
    end
  end

  describe 'revert' do
    it "raises if the checksum isn't correct" do
      dictionary = EasyPin::NUMERIC

      generator = EasyPin::Generator.new(base_converter: EasyPin::BaseConverter.new(dictionary.size),
                                         checksum_generator: EasyPin::ChecksumGenerator.new(dictionary.size),
                                         tumbler: IdentityTumbler.new,
                                         padding: 4,
                                         separator: '')

      code = generator.generate(1234)
      expect(code).to eq '12340'

      expect{generator.revert('12341')}.to raise_error(EasyPin::InvalidChecksum)
    end
  end

  describe EasyPin::BaseConverter do
    it 'converts base 16' do
      converter = EasyPin::BaseConverter.new(16)

      expect(converter.convert(1)).to eq [1]
      expect(converter.convert(5)).to eq [5]
      expect(converter.convert(10)).to eq [10]
      expect(converter.convert(16)).to eq [1, 0]
      expect(converter.convert(256)).to eq [1, 0, 0]
    end
  end

  describe EasyPin::ChecksumGenerator do
    it 'sums all parts, mods by the base and appends' do
      cg = EasyPin::ChecksumGenerator.new(7)

      expect(cg.checksum([1])).to eq [1, 1]
      expect(cg.checksum([6])).to eq [6, 6]
      expect(cg.checksum([3, 4])).to eq [3, 4, 0]
    end

    it 'does nothing when validating a good code' do
      cg = EasyPin::ChecksumGenerator.new(3)

      cg.validate([2, 2])
      cg.validate([1, 2, 0])
      cg.validate([2, 2, 1])
    end

    it 'raises when validating a bad code' do
      cg = EasyPin::ChecksumGenerator.new(3)

      expect{ cg.validate([2, 1]) }.to raise_error(EasyPin::InvalidChecksum)
      expect{ cg.validate([1, 2, 1]) }.to raise_error(EasyPin::InvalidChecksum)
    end
  end

  describe EasyPin::Tumbler do
    it 'maps each part to a randomly shuffled character - and back again' do
      dictionary = double(shuffle: 'abc'.chars)
      tumbler = EasyPin::Tumbler.new(dictionary, double(rand: 0))

      expect(tumbler.tumble([0, 1, 2])).to eq ['a', 'b', 'c']
      expect(tumbler.tumble([2, 1, 0])).to eq ['c', 'b', 'a']

      expect(tumbler.untumble(['a', 'b', 'c'])).to eq [0, 1, 2]
      expect(tumbler.untumble(['c', 'b', 'a'])).to eq [2, 1, 0]

      dictionary = double(shuffle: 'cba'.chars)
      tumbler = EasyPin::Tumbler.new(dictionary, double(rand: 0))

      expect(tumbler.tumble([0, 1, 2])).to eq ['c', 'b', 'a']
      expect(tumbler.tumble([2, 1, 0])).to eq ['a', 'b', 'c']

      expect(tumbler.untumble(['c', 'b', 'a'])).to eq [0, 1, 2]
      expect(tumbler.untumble(['a', 'b', 'c'])).to eq [2, 1, 0]
    end
  end

  class IdentityTumbler
    def tumble(parts) ; parts.map(&:to_s) end
    def untumble(parts) ; parts.map(&:to_i) end
  end

end
