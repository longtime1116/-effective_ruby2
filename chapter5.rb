module PreventInheritance
  class InheritanceError < StandardError
  end

  # class に直接書くなら、def self.inherited で書く
  def inherited(child)
    # クラスフックの中ではsuperを使った方がいい。他のモジュールのクラスフックの処理を実行できるようにしておく。
    super
    raise(InheritanceError, "#{child} cannot inherit from #{self}")
  end
end

begin
  Array.extend(PreventInheritance)
  class BetterArray < Array
  end
rescue StandardError => e
  p e
end

class Parent
  def hoge
    p 'parent hoge'
  end

  def fuga
    p 'parent fuga'
  end
end

class MethodHooks < Parent
  def self.method_added(m)
    p "method added(#{m})"
  end

  def self.method_removed(m)
    p "method removed(#{m})"
  end

  def self.method_undefined(m)
    p "method undefined(#{m})"
  end

  def self.singleton_method_added(m)
    p "singleton method added(#{m})"
  end

  def hoge
    p 'hoge'
  end

  def fuga
    p 'fuga'
  end

  def self.this_is_class_method
    p 'this_is_class_method'
  end
end
p '----- add method'
a = MethodHooks.new
MethodHooks.define_method('new hoge') do
  p 'new hoge'
end
a.hoge
p '----- remove method'
MethodHooks.remove_method('hoge')
a = MethodHooks.new
a.hoge

p '----- undef method'
MethodHooks.undef_method('fuga')
a = MethodHooks.new
begin
  a.fuga
rescue StandardError => e
  p e
end

p 'Hash に委譲するのを、メタプロ使ってやる'
class HashProxy
  Hash.public_instance_methods(false).each do |name|
    define_method(name) do |*args, &block|
      @hash.send(name, *args, &block)
    end
  end
  def initialize
    @hash = {}
  end
end
hash = HashProxy.new
p hash.select { |_h| true }.class #=> このやり方だともちろんHashが返ってくる
p hash.public_methods(false).sort.take(5)

p 'モンキーパッチではなくリファインメント'

module OnlySpace
  HOGE = true
  refine(String) do
    def only_space?
      HOGE
    end
  end
end

class Person
  using(OnlySpace)
  def initialize(name)
    @name = name
  end

  def valid?
    p "only_namespace: #{@name.only_space?}"
    !@name.only_space?
  end

  def display(io = $stdout)
    io.puts(@name)
  end
end
a = Person.new('name')
p a.valid?
a.display

module LogMethod
  def log_method(method)
    original_behavior_method = without_logging_method_name(method)
    raise("#{original_behavior_method} is not a unique name") if instance_methods.include?(original_behavior_method)

    alias_method(original_behavior_method, method)
    define_method(method) do |*args, &block|
      p "calling method #{method}"
      result = send(original_behavior_method, *args, &block)
      p "method #{method} returned #{result}"
      result
    end
  end

  def unlog_method(method)
    original_behavior_method = without_logging_method_name(method)
    raise("was #{original_behavior_method} already removed?") unless instance_methods.include?(original_behavior_method)

    remove_method(method)
    alias_method(method, original_behavior_method)
    remove_method(original_behavior_method)
  end

  private

  def without_logging_method_name(method)
    "#{method}_without_logging".to_sym
  end
end

Array.extend(LogMethod)
Array.log_method(:first)
p [1, 2, 3].first
p [4, 5, 6].first_without_logging
Array.unlog_method(:first)
p [1, 2, 3].first
begin
  p [4, 5, 6].first_without_logging
rescue StandardError => e
  p e
end

# Proc とかその辺りは、省略。lambdaはちょっと書いてみる。なんか調べたら、Procでcurry化もできるらしい。
f_lambda = lambda { |x|
  x * 2
}
f_arrow = ->(x) { x * 2 }
p f_lambda.call(5)
p f_arrow.call(5)

# prepend はそれを呼び出したクラスよりも"前"に差し込まれる点に注意が必要
module A
  def hoge
    'A'
  end
end

module B
  def hoge
    'B'
  end
end

class CInclude
  include A
  include B
  def hoge
    'C'
  end
end

class CPrepend
  prepend A
  prepend B
  def hoge
    'C'
  end
end
p CInclude.ancestors
p CInclude.new.hoge

p CPrepend.ancestors
p CPrepend.new.hoge
