require File.expand_path('../coord', __FILE__)

class Array
  def other(than)
    find { |o| o != than }
  end
  
  def select_max_by
    best = map { |e| yield(e) }.max
    select { |e| yield(e) == best }
  end
  
  # 1.8 problems for Hash
  def keys
    map { |e| e.first }
  end
  
  unless [].respond_to? :each_with_object
    def each_with_object(obj)
      self.each { |e|
        yield(e, obj)
      }
      obj
    end
  end
  
  unless [].respond_to? :sample
    def sample
      self[rand(size)]
    end
  end
end

class Player
  attr_reader :name, :shots, :fired
  
  NAME = /\w+/
  SIDE = 10
  ALL_COORDS = (0...SIDE**2).map { |i| Coord.new(i % SIDE, i / SIDE) }

  def initialize(name, ships = [5, 4, 3, 3, 2])
    @name = name
    @ships = ships
    @ships_cells = []
    @shots = []
    @fired = {}
    @sinking = []
  end

  def fire(coord, hit)
    @fired[Coord.new(coord)] = (hit.to_sym == :hit)
  end

  # Only for ourselves
  def place_ships
    ships = "SHIPS"
    @ships.each { |size|
      begin
        current_ship_cells = []
        if rand < 0.5 # Horizontal
          d = :H
          x = rand(SIDE-size)
          y = rand(SIDE)
        else # Vertical
          d = :V
          x = rand(SIDE)
          y = rand(SIDE-size)
        end
        size.times { |i| current_ship_cells << Coord.new( x + (d == :H ? i : 0), y + (d == :V ? i : 0) ) }
      end until (@ships_cells & current_ship_cells).empty?

      @ships_cells += current_ship_cells
      ships << " #{size}:#{Coord.new(x, y)}:#{d}"
    }
    ships
  end
  
  def shot!(n)
    targets = []
    @sinking = @fired.select { |c,r| r }.keys
    
    # 1 Sinking
    while hit = @sinking.pop
      targets += sink_that_ship!(hit)
      targets.uniq!
      if targets.length >= n
        targets = targets[0...n]
        break
      end
    end
    
    # 2 Secure perimeter
    if targets.length < n
      targets += shots_around_hits((n-targets.length)/2)
    end
    
    @shots += targets
    
    # 3 Try new locations
    while targets.length < n
      targets << shot
    end
    
    raise "We've got a problem: #{@fired.keys & shots}" if !(@fired.keys & targets).empty?
    
    "SHOTS #{targets.join(' ')}"
  end
  
  def shots_around_hits(n)
    @fired.select { |c, v|
      v
    }.keys.map { |c|
      Coord::DIRECTIONS.map { |d| c+d }
    }.flatten.uniq.select { |c|
      c.valid?(@fired)
    }.sort_by { rand }[0...n]
  end
  
  def find_same_dir(start, dir)
    Coord::DIRS[dir].each_with_object([start]) { |add, coords|
      c = start
      while c += add and c.valid? and @fired[c]
        coords << c
      end
    }
  end
  
  def sink_that_ship!(start)
    # Find shooted H and V
    dirs = {
      :h => find_same_dir(start, :h),
      :v => find_same_dir(start, :v)
    }
    dirs.each_value { |dir| @sinking -= dir }
    if dirs[:h].length == dirs[:v].length
      # We got only one coord, or there are as much tries in H & V. So we choose random dir
      dir = rand < 0.5 ? :h : :v
      shooted = dirs[dir]
    else
      # We know which direction is more interesting
      dir, shooted = dirs.sort_by { |_,d| d.length }.last
    end

    coords = Coord::DIRS[dir].map { |add|
      shooted.map { |s| s+add }.find { |c|
        c.valid?(@fired)
      }
    }.compact.select { |c| c.valid?(@fired) }
    
    n_shoots = ((@ships.inject { |sum, n| sum + n } - @fired.select { |_,r| r }.size) / @ships.size + 0.5).to_i
    
    if coords.size == 1 # we know which way to go, let's shoot a max !
      way_to_go = coords.other(start)-start
    else # we go both side
      way_to_go = Coord::DIRS[dir].sample
    end

    n_shoots.times { |i|
      c = start + way_to_go*(i+1)
      if c.valid?(@fired)
        coords << c
      else
        break
      end
    }

    coords
  end
  
  def shot
    free = ALL_COORDS - @shots
    # free = free.shuffle[0..(free.size/2)] # To make it quicker ... but less accurate
    s = free.select_max_by { |c| c.freespace_around(@shots) }.sample
    @shots << s
    s
  end
  
  def random_shot
    begin
      shot = Coord.new(rand(SIDE), rand(SIDE))
    end while shot.in?(ALL_COORDS - @shots)
    shot
  end
end

if __FILE__ == $0
  require "test/unit"

  class TestPlayer < Test::Unit::TestCase
    def setup
      @p = Player.new('test_player')
      
      @p.fire('B1', :miss)
      @p.fire('B3', :hit)
      @p.fire('C3', :hit)
    end
    
    def test_sink
      assert_equal [Coord.new('B3'), Coord.new('C3')], @p.find_same_dir(Coord.new('B3'), :h)
      assert_equal [Coord.new('B3')], @p.find_same_dir(Coord.new('B3'), :v)
    end
    
    def test_shot
      assert_equal "SHOTS A3 D3", @p.shot!(2)
      
      p = Player.new('test_player')
      p.fire('F6', :hit)
      r = p.shot!(2)
      assert ["SHOTS F5 F7", "SHOTS E6 G6"].include?(r), r
      
      p = Player.new('test_player2')
      p.fire('H2', :hit)
      p.fire('G2', :hit)
      p.fire('I2', :miss)
      expected = "SHOTS F2 E2"
      assert_equal expected, p.shot!(5)[0...expected.length]
    end
  end
end

=begin
+----+---+---+---+---+---+---+---+---+---+---+
|    | A | B | C | D | E | F | G | H | I | J |
+----+---+---+---+---+---+---+---+---+---+---+
| 1  |   | 0 |   |   |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 2  |   |   |   |   |< >|< >|<1>|<1>|<0>|   |
+----+---+---+---+---+---+---+---+---+---+---+
| 3  |< >|<1>|<1>|< >|   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 4  |   |   |   |   |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 5  |   |   |   |   |   | ? |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 6  |   |   |   |   |<?>|<1>|<?>|   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 7  |   |   |   |   |   | ? |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 8  |   |   |   |   |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 9  |   |   |   |   |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
| 10 |   |   |   |   |   |   |   |   |   |   |
+----+---+---+---+---+---+---+---+---+---+---+
=end
