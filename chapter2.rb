puts '継承階層'

module ThingsWithNames1
  def name
    'ThingsWithNames1'
  end
end

module ThingsWithNames2
  def name
    'ThingsWithNames2'
  end
end

class Person
  include(ThingsWithNames1)
  include(ThingsWithNames2)
end

class Customer < Person
  def self.where_am_i?; end
end

customer = Customer.new
p customer.name
p Person.superclass
p customer.class.superclass
p customer.class.singleton_class
p customer.class.singleton_class.instance_methods(false)

puts 'attr_accessor は、ゲッターとセッターのメソッドを生やす。インスタンス変数を直接いじらず、これによって生まれたメソッドを通して扱うことが可能となる'
class Name
  attr_accessor(:first, :last)

  def initialize(first, last)
    self.first = first
    self.last = last
  end

  def full
    first + ' ' + last
  end
end

taro = Name.new('Taro', 'Tanaka')
p taro.full
p taro.first

puts '構造化データの表現にはStructを使う'
require 'csv'
class AnnualWeatherHash
  def initialize(file_name)
    @readings = []
    CSV.foreach(file_name, headers: true) do |row|
      @readings << {
        date: Date.parse(row[0]),
        high: row[1].to_f,
        low: row[2].to_f
      }
    end
  end

  def mean
    return 0.0 if @readings.size.zero?

    total = @readings.reduce(0.0) do |sum, reading|
      sum + (reading[:high] + reading[:low]) / 2.0
    end
    total / @readings.size.to_f
  end
end

class AnnualWeatherStruct
  Reading = Struct.new(:date, :high, :low)

  def initialize(file_name)
    @readings = []
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
p AnnualWeatherHash.new('./temperature.csv').mean
p AnnualWeatherStruct.new('./temperature.csv').mean

puts '==/equal?/eql?'
p 'foo' == 'foo'
p 'foo'.object_id
p 'foo'.object_id
p 'foo'.equal?('foo')
foo = 'foo'
p foo.equal?(foo)
p foo.object_id

# hash の key 比較(eql?)はデフォルトではobject_idで比較するので、以下はaとbでkeyが異なるものとされてしまう
class Color
  def initialize(name)
    @name = name
  end
end
a = Color.new('pink')
b = Color.new('pink')
color_hash = { a => 'like', b => 'love' }
p color_hash

class Color2
  attr_reader :name

  def initialize(name)
    @name = name
  end

  # hash値が衝突しないように
  def hash
    name.hash
  end

  # object_idではなくnameで
  def eql?(other)
    name.eql?(other.name)
  end
end

a = Color2.new('pink')
b = Color2.new('pink')
color2_hash = { a => 'like', b => 'love' }
p color2_hash

puts 'case等値演算子の === はcaseで内部的に使われている。正規表現でマッチしているものを返す挙動にしたりしている'
class CaseExample
  def self.parse_command(command)
    case command
    when 'start' then 'start'
    when 'stop', 'quit' then 'quit'
    when /^cd\s+(.+)$/ then "cd #{::Regexp.last_match(1)}" # === の左辺に正規表現があるからこれができる
    when Numeric then "timer(#{command})"
    else raise(command)
    end
  end
end
begin
  p CaseExample.parse_command('start')
  p CaseExample.parse_command('quit')
  p CaseExample.parse_command('cd ~/')
  p CaseExample.parse_command(4)
  p CaseExample.parse_command('hoge')
rescue StandardError => e
  p e
end

# Class、Module も === を定義しており、インスタンスならばtrueを返す
p [1, 2, 3].is_a?(Array)
p [1, 2, 3] === Array
# p Array === [1,2,3] # ← auto format でis_aを使うように書き換えられてしまう・・・
