# 自分でエラーを作ることで、自分の捕捉したいエラーのみを上流でキャッチできる
class MyError < StandardError
end

begin
  raise(MyError, 'This is my original Error Class!')
rescue MyError => e
  p e
end

# ensure は単体でも使える。戻り値は "hoge"。ensureの中でreturnをすると制御フローが変わったり例外が飲み込まれたりして予期しない形になりがちなので注意
def hoge
  'hoge'
ensure
  p 'in ensure'
  'ensure'
end
p hoge #=> "hoge"

# File.open のように、blockが終わったら自動でensure処理するし、そうでないやり方もできるクラスの例
class Lock
  def self.acquire
    lock = new
    lock.exclusive_lock!
    if block_given?
      yield(lock)
    else
      lock
    end
  ensure
    lock.unlock if block_given? && lock
  end

  def exclusive_lock!
    p 'exclusive lock start!'
  end

  def unlock
    p 'unlock'
  end
end

Lock.acquire do |lock|
  # ここで処理を書くと、終わった後にlock解除してくれる
end
lock = Lock.acquire
lock.unlock

# retry 作法
# begin 節の外で変数定義
# retries = 0
# begin
#   service.update(record)
# rescue VendorDeadlockError => e
#   raise if retries >= 3
#
#   retries += 1
#   logger.warn("API failure: #{e}, retrying...")
#   # 指数的に増やしていく。同じ時間間隔で繰り返すと状況を悪化させて別の問題が起きる可能性もある
#   sleep(5**retries)
#   retry
# end

# throw catch はスコープから飛び出したいときに使うと便利。
color1 = %w[red yellow green]
color2 = %w[purple blue pink black]
favorite_color_combinations = [%w[red blue], %w[black black]]
match = catch(:jump) do
  color1.each do |c1|
    color2.each do |c2|
      throw(:jump, [c1, c2]) if favorite_color_combinations.include?([c1, c2])
    end
  end
  nil
end
p match
