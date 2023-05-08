puts 'false と nil 以外は truthy'
p true.class
p false.class
p '0: truthy' if 0
p 'nil: truthy' if nil
p 'false: truthy' if false

class BadOverride
  def ==(_other)
    true
  end
end

puts 'false は 左側に書くとFalseClass#==メソッドを呼び出せて安心'
p false == BadOverride.new
p BadOverride.new == false

puts 'to_a とか to_i とか to_f とかで明示的な型に変換することで、nilチェックを包括することができる'
def fix_title(title)
  title.to_s.capitalize
end
p fix_title('hoge')
p fix_title(nil)

first = 'Taro'
middle = nil
last = 'Tanaka'

puts 'compact で nil を消去'
p [first, middle, last].compact.join(' ')

puts '定数は freeze'
module Defaults
  NETWORKS = [
    '192.168.1',
    '192.168.1'
  ]
end.map!(&:freeze).freeze
Defaults.freeze
# p Defaults::NETWORKS[0] << 'hoge'
# p Defaults::NETWORKS[0] = 'hoge'
# p Defaults::NETWORKS = 'NETWORKS'
p Defaults::NETWORKS
