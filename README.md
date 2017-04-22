# easy-pin
Generate unique PIN codes from an integer.
A bit like: [hashids](hashids.org)
or [integer_hash](github.com/icehero/integer_hash)

## So why is this one different?
* easy-pin is designed for the generation of easy to read and verbally recite
  pin codes rather than just id obfuscation.
* The last digit of the pin code is a check sum the guarantees that a single
  mistake won't be mistaken for a valid pin code.
* The 'dictionary' of symbols available can be configured to be smaller than
  16 and is not limited to single characters.

Usage:
```
gem install easy-pin
```

```
require 'easy_pin'

generator = EasyPin::Generator.build(random_seed: 42)

generator.generate(97)
 => "ztj2"
generator.revert('ztj2')
 => 97

generator.revert('ztj3')
EasyPin::InvalidChecksum: invalid checksum 9, expected 22
```

Numeric codes can be generated:
```
generator = EasyPin::Generator.build(random_seed: 42, dictionary: EasyPin::NUMERIC)

generator.generate(97)
 => "8273"
generator.revert('8273')
 => 97
```

You can use your own dictionary, the padding can be changed too:
```
generator = EasyPin::Generator.build(random_seed: 42, dictionary: ['a','b','c'], padding: 2)

generator.generate(1)
 => "bc"
generator.generate(2)
 => "ca"
generator.generate(3)
 => "bbb"

generator = EasyPin::Generator.build(random_seed: 42, dictionary: ['a','b','c'], padding: 8)

generator.generate(1)
 => "abababab"
generator.generate(3)
 => "ababaabb"
generator.generate(1_000_000)
 => "babacabaaaaacb"
```

When using multi character dictionary items, add a separator that doesn't appear in the dictionary:
```
generator = EasyPin::Generator.build(random_seed: 42, dictionary: ['cat', 'dog'], separator: '-')

generator.generate(97)
 => "cat-dog-dog-dog-dog-cat-cat-cat"
generator.revert("cat-dog-dog-dog-dog-cat-cat-cat")
 => 97
```

