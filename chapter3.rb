# 引数でわたされるオブジェクトは基本的に参照。Fixnumのような例外はあるが。
def hoge(array, _num)
  array << 'c'
  num = 4
end
x = %w[a b]
n = 3
hoge(x, n)
p x
p n

# dup で shallow copy して使う
class Tuner
  def initialize(presets)
    @presets = clean(presets.dup)
  end

  def clean(presets)
    presets.reject { |f| f[-1].to_i.even? }
  end
end

p presets = ['90.1', '106.2', '88.5']
p Tuner.new(presets)

# 独自クラスのコピーは initialize_copy をオーバーライドすれば制御できる。
# 既存のコレクションクラスのディープコピーが必要なら Marshal dump という手もある

animals = %w[Monkey Bird]
animals2 = Marshal.load(Marshal.dump(animals))
animals2.each(&:upcase!)
p animals
p animals2

# Kernel::Array を使って、nilもスカラーオブジェクトも配列も統一的に扱う
class Pizza
  def initialize(toppings)
    @toppings = Array(toppings).map do |topping|
      topping.upcase
    end
  end
end
p Pizza.new(nil)
p Pizza.new('onion')
p Pizza.new(%w[onion pepperoni])

# Setはhash値で木構造を作るので、探索をO(log_n)でやってくれる。配列でinclude?を使うとO(n)なのでパフォーマンスに影響が出る場合がある。
require('set')
require('csv')
class AnnualWeatherStructSet
  Reading = Struct.new(:date, :high, :low) do
    def eql?(other)
      date.eql?(other.date)
    end

    def hash
      date.hash
    end
  end

  def initialize(file_name)
    @readings = Set.new
    CSV.foreach(file_name, headers: true) do |row|
      @readings << Reading.new(Date.parse(row[0]),
                               row[1].to_f,
                               row[2].to_f)
    end
  end

  def mean
    return 0.0 if @readings.size.zero?

    total = @readings.reduce(0.0) do |sum, reading|
      sum + (reading.high + reading.low) / 2.0
    end
    total / @readings.size.to_f
  end
end

aw = AnnualWeatherStructSet.new('./temperature.csv')
p aw.mean

# reduce使おう
# before
hash = {}
%w[a b c].each do |element|
  hash[element] = true
end
p hash
# after
hash = %w[a b c].reduce({}) do |hash, element|
  hash.update(element => true)
end
p hash

# hash のデフォルト値
# この場合は reduce ではなく each_with_object を使う方がいいらしい。
hoge = %w[a b c a].each_with_object(Hash.new(0)) do |element, hash|
  hash[element] += 1
end
p hoge

# デフォルト値をこれくしょんにする際には注意が必要。同一の参照がその都度使われるので、意図せぬ挙動になる。ブロックで毎度生成しよう。
h = Hash.new { [] }
h[:weekdays] = h[:weekdays] << 'Monday'
h[:months] = h[:months] << 'January'
p h[:weekdays]
p h[:holidays]
p h.keys
# ちゃんと has_key? を使う。デフォルト値がnilであることに暗黙的に依存しているコードを書いてはならない
p 'hoge' if h[:holidays]
p 'fuga' if h.has_key?(:holidays)

h = Hash.new { |hash, key| hash[key] = [] }
h[:weekdays] << 'Monday'
h[:holidays]
p h.keys
p 'hoge' if h[:holidays]
p 'fuga' if h.has_key?(:holidays)

# デフォルト値よりもfetchを使った方がいいこともある
h = {}
p h[:weekdays] = h.fetch(:weekdays, []) << 'Monday'
begin
  h.fetch(:missing_key)
rescue StandardError => e
  p e
end

# Fowardable モジュールの def_delegators で委譲。
class LikeArray < Array
end
x = LikeArray.new([1, 2, 3])
p x.reverse.class #=> Array になってしまう！
p x === [1, 2, 3] #=> true になってしまう！

require('forwardable')
class RaisingHash
  extend(Forwardable)
  include(Enumerable)
  def_delegators(:@hash, :[], :[]=, :delete, :each, :keys, :values, :length, :empty?, :has_key?)
  def_delegator(:@hash, :delete, :erase!)

  def initialize
    @hash = Hash.new do |_hash, key|
      raise(KeyError, "invalid key #{key}")
    end
  end

  def initialize_copy(_other)
    @hash = @hash.dup
  end

  def freeze
    @hash.freeze
    super
  end

  def invert
    other = self.class.new
    other.replace!(@hash.invert)
    other
  end

  protected

  def replace!(hash)
    hash.default_proc = @hash.default_proc
    @hash = hash
  end
end

hash = RaisingHash.new
hash[:hoge] = 1
hash[:fuga] = 2
hash.erase!(:hoge)
p hash
begin
  hash[:foo]
rescue StandardError => e
  p e
end
p hash.invert.class # invert を override していないと Hash が返ってしまう
