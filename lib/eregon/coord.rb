class String
  unless "".respond_to? :ord
    def ord
      self.unpack('c')[0]
    end
  end
end

class Coord < Struct.new(:x, :y)
  SIDE = 10
  
  N = Coord.new(0,-1)
  E = Coord.new( 1,0)
  S = Coord.new(0, 1)
  W = Coord.new(-1,0)
  DIRS = { :h => [W, E], :v => [N, S] }
  DIRECTIONS = [N, E, S, W]
  
  def initialize(*args)
    case args.length
    when 1
      args[0] =~ /\A([A-Z]+)([0-9]+)\z/
      x, y = $~.captures
      super(x.ord - 'A'.ord, y.to_i - 1)
    when 2
      super(*args)
    end
  end
  
  def to_s
    "#{(x+'A'.ord).chr}#{y+1}"
  end
  alias :inspect :to_s

  [:+, :-].each { |m|
    define_method(m) { |c|
      Coord.new(x.send(m,c.x), y.send(m,c.y))
    }
  }

  def * n
    Coord.new(x*n, y*n)
  end

  def neighbours
    DIRECTIONS.map { |dir| self + dir }
  end

  def distance(c)
    Math.sqrt( (x-c.x)**2 + (y-c.y)**2 )
  end

  def in?(o)
    case o
    when Array
      o.include?(self)
    when Hash
      o.keys.include?(self)
    else
      raise
    end
  end

  def valid?(ary = [])
    if ary.empty?
      (0...SIDE) === x and (0...SIDE) === y
    else
      (0...SIDE) === x and (0...SIDE) === y and not in?(ary)
    end
  end

  # 1: 8
  # 2: 8*2
  # 3: 8*3
  FREESPACE_LEVELS = Array.new(SIDE) { |i|
    l = i+1
    c = (N+W)*l # NW
    [E, S, W, N].inject([]) { |lvl, dir|
      (l*2).times {
        lvl << c
        c += dir
      }
      lvl
    }
  }
  
  def freespace_around(shots)
    FREESPACE_LEVELS.inject(0.0) { |i, lvl|
      continue = true
      lvl.each { |add|
        c = self+add
        next unless c.valid?
        if !c.in?(shots)
          i += 1.0 / self.distance(c) * (FREESPACE_LEVELS.index(lvl)+1)
        else
          continue = false
        end
      }
      return i unless continue
      i
    }
  end
end

if __FILE__ == $0
  require "test/unit"

  class TestCoord < Test::Unit::TestCase
    def setup
      @a = Coord.new(0,0)
      @c = Coord.new(2,3)
    end
    
    def c(actual, expected)
      assert_equal expected, actual
    end
    
    def test_new
      c Coord.new("A1").to_a, [0,0]
      c Coord.new("J10").to_a, [9,9]
      c [@c.x, @c.y], [2,3]
    end
    
    def test_to_s
      c @c.to_s, "C4"
      c Coord.new("D5").to_s, "D5"
    end
    
    def test_in?
      assert @c.in?([@a,@c])
      assert !@c.in?([@a])
      assert @c.in?({@c=>false, @a => nil})
      assert !@c.in?({@a => true})
    end
    
    def test_valid?
      assert @c.valid?
      assert @c.valid?([])
      assert !@c.valid?([@c])
      assert !Coord.new(10,9).valid?
    end
    
    def test_neighbours
      c @c.neighbours, [Coord.new(2,2), Coord.new(3,3), Coord.new(2,4), Coord.new(1,3)]
    end
    
    def test_freespace_around
      shooted = %w{B1 D1 B3 C2}.map { |s| Coord.new(s) }
      
      s = 1/Math.sqrt(2)
      
      assert_equal 2+2*s, Coord.new("E1").freespace_around(shooted)               # 4
      assert_equal 1+4*s, Coord.new("B2").freespace_around(shooted)               # 5
      assert_equal 11.406135888745856, Coord.new("F1").freespace_around(shooted)  # 13
      assert_equal 69.79675884855767, Coord.new("J10").freespace_around(shooted)  # 78
      assert_equal 4+3*s, Coord.new("D3").freespace_around(shooted)               # 7
    end
  end
end

=begin
+----+---+---+---+---+---+---+---+---+---+---+
|    | A | B | C | D | E | F | G | H | I | J |
+----+---+---+---+---+---+---+---+---+---+---+
| 1  |   | X |   | X |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 2  |   |   | X |   |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 3  |   | X |   |   |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 4  |   |   |   |   |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 5  |   |   |   |   |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 6  |   |   |   |   |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 7  |   |   |   |   |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 8  |   |   |   |   |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 9  |   |   |   |   |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 10 |   |   |   |   |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
=end
