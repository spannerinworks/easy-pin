require 'easy_pin'
require 'prime'

RSpec.describe EasyPin do

  it 'generates unique revertable pin codes that are made up of the dictionary' do
    generator = EasyPin::Generator.build

    uniq_hash ||= {}

    (1..100_000).each do |i|
      code = generator.generate(i)

      expect(generator.revert(code)).to eq i

      expect(uniq_hash.key?(code)).to eq false

      expect(EasyPin::EASY_PUBLIC).to include(*code.chars.uniq)

      uniq_hash[code] = true
    end
  end

  it 'raises if an integer < 1 is supplied' do
    generator = EasyPin::Generator.build

    expect{ generator.generate(0) }.to raise_error(EasyPin::InvalidInput)
  end

  describe 'revert' do
    it "raises if the checksum isn't correct" do
      dictionary = EasyPin::NUMERIC

      generator = EasyPin::Generator.new(base_converter: EasyPin::BaseConverter.new(dictionary.size),
                                         checksum_generator: EasyPin::ChecksumGenerator.new(dictionary.size),
                                         tumbler: IdentityTumbler.new,
                                         padder: EasyPin::Padder.new(4),
                                         formatter: EasyPin::Formatter.new(''))

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

    it 'raises when validating a code with 1 character wrong' do
      cg = EasyPin::ChecksumGenerator.new(3)

      expect{ cg.validate([1, 1, 0]) }.to raise_error(EasyPin::InvalidChecksum)
      expect{ cg.validate([1, 3, 0]) }.to raise_error(EasyPin::InvalidChecksum)

      expect{ cg.validate([0, 2, 0]) }.to raise_error(EasyPin::InvalidChecksum)
      expect{ cg.validate([2, 2, 0]) }.to raise_error(EasyPin::InvalidChecksum)

      expect{ cg.validate([1, 2, 1]) }.to raise_error(EasyPin::InvalidChecksum)
      expect{ cg.validate([1, 2, 2]) }.to raise_error(EasyPin::InvalidChecksum)
    end

    it "raises when validating a code 2 characters wrong - so long as the errors don't add up to the base" do
      cg = EasyPin::ChecksumGenerator.new(3)

      # good
      cg.validate([1, 1, 2])

      # out by 2
      expect{ cg.validate([2, 2, 2]) }.to raise_error(EasyPin::InvalidChecksum)
      expect{ cg.validate([0, 0, 2]) }.to raise_error(EasyPin::InvalidChecksum)

      # oh well
      expect{ cg.validate([2, 0, 2]) }.to_not raise_error
      expect{ cg.validate([0, 2, 2]) }.to_not raise_error
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

    it 'raises errors when the input is invalid' do
      tumbler = EasyPin::Tumbler.new('abc'.chars, double, 3)

      expect{ tumbler.validate([-1]) }.to raise_error(EasyPin::InvalidInput)
      expect{ tumbler.validate([3]) }.to raise_error(EasyPin::InvalidInput)
      expect{ tumbler.validate([1,1,1,1]) }.to raise_error(EasyPin::InvalidInput)
      expect{ tumbler.validate(['d']) }.to raise_error(EasyPin::InvalidInput)
      expect{ tumbler.validate([Object.new]) }.to raise_error(EasyPin::InvalidInput)
    end
  end

  class IdentityTumbler
    def tumble(parts) ; parts.map(&:to_s) end
    def untumble(parts) ; parts.map(&:to_i) end
  end

end
