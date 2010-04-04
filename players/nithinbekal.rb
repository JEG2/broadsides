# This program implements a player for the Broadsides game as part of the
# Ruby Programming Challenge for Newbies (RPCFN #7).
#
# Author::    Nithin Bekal

# This class represents the 10x10 board used in this challenge. The variable
# @board holds the current status of all the tiles on the board. The statuses
# are described below:
#
#   * . - The status of the tile is unknown.
#   * h - The target has already been hit.
#   * m - The target has been shot at but was empty.
#   * q - The target is a neighbor to an already hit target.
class Board
  attr_accessor :board
  def initialize
    @board = [
      ['.','.','.','.','.','.','.','.','.','.',],
      ['.','.','.','.','.','.','.','.','.','.',],
      ['.','.','.','.','.','.','.','.','.','.',],
      ['.','.','.','.','.','.','.','.','.','.',],
      ['.','.','.','.','.','.','.','.','.','.',],
      ['.','.','.','.','.','.','.','.','.','.',],
      ['.','.','.','.','.','.','.','.','.','.',],
      ['.','.','.','.','.','.','.','.','.','.',],
      ['.','.','.','.','.','.','.','.','.','.',],
      ['.','.','.','.','.','.','.','.','.','.',],
    ]
  end

  def to_s
    s = "     A B C D E F G H I J \n"
    (1..10).each do |x|
      s += "%5s" %(x.to_s + '   ')
      ("A".."J").each do |y|
        s += "#{get_status("#{y}#{x}")} "
      end
      s += "\n"
    end
    s
  end

  # Returns status of the tile.
  def get_status pos
    y = pos[0] - 65
    x = pos[1,2].to_i - 1
    board[x][y]
  end

  # Sets the status of the specified tile.
  def set_status pos, status
    y = pos[0] - 65
    x = pos[1,2].to_i - 1
    board[x][y] = status
  end

  # Returns an array of targets that have already been hit.
  def hit_targets
    hits = []
    ("A".."J").each do |x|
      (1..10).each do |y|
        hits.push "#{x}#{y}" if is_hit? "#{x}#{y}"
      end
    end
    hits
  end

  # Returns an empty tile.
  def empty_tiles
    tiles = []
    ("A".."J").each { |x| (1..10).each { |y| tiles.push "#{x}#{y}" if is_empty? "#{x}#{y}" } }
    tiles.sort_by { rand }
  end

  # Returns array of targets. Neighbors of hit targets are queued 
  # first, then other targets in random order.
  def get_new_targets
    targets = []
    hit_targets.each do |t|
      targets.push neighbors(t)
      neighbors(t).each { |n| set_status(n, 'q') }
    end
    targets.push(empty_tiles).flatten
  end

  # Returns true if the tile's status is unknown.
  def is_empty? pos
    get_status(pos)== '.' ? true : false
  end

  # Returns true if the tile has already been hit.
  def is_hit? pos
    get_status(pos)== 'h' ? true : false
  end

  # Returns the tiles to the top, left, right and bottom of a given tile.
  def neighbors pos
    x = pos[0,1]
    y = pos[1,2]
    neighbors_list = []
    unless y == "1"
      top = "#{x}#{y.to_i-1}"
      neighbors_list.push top unless ['h', 'm'].include? get_status(top)
    end
    unless y == "10"
      bottom = "#{x}#{y.to_i+1}"
      neighbors_list.push bottom unless ['h', 'm'].include? get_status(bottom)
    end
    unless x == "J"
      right = "#{x.next}#{y}"
      neighbors_list.push right unless ['h', 'm'].include? get_status(right)
    end
    unless x == "A"
      left = "#{(x[0]-1).chr}#{y}"
      neighbors_list.push left unless ['h', 'm'].include? get_status(left)
    end
    neighbors_list
  end

  # Uses the string returned by the game to set the status of the tiles that
  # were most recently shot at.
  def update_hits_and_misses info
    shots = info.split
    shots.each do |s|
      loc = s.split(':')[0]
      status = s.split(':')[1][0].chr
      self.set_status loc, status
    end
  end
end

# The board is divided into 5 blocks and the ships are placed, one in each
# block. The bigger ships are placed further away from the position A1 and the
# shorter ones are closer. Two of the shorter ones are placed vertically and
# the rest horizontal.
def place_ships_randomly
  str  = "5:" + (rand(6) +  97).chr.upcase + (rand(3) + 8).to_s + ":H "
  str += "4:" + (rand(2) + 102).chr.upcase + (rand(3) + 5).to_s + ":H "
  str += "3:" + (rand(3) + 102).chr.upcase + (rand(4) + 1).to_s + ":H "
  str += "3:" + (rand(5) +  97).chr.upcase + (rand(2) + 4).to_s + ":V "
  str += "2:" + (rand(5) +  97).chr.upcase + (rand(2) + 1).to_s + ":V"
end

$stdout.sync = true

b = Board.new

ARGF.each_line do |line|
  case line
  when /\AACTION SHIPS\b/
    # Call the method to get random position of the ships within the blocks
    # defined for each of them
    puts "SHIPS " + place_ships_randomly

  when /\AACTION SHOTS (\d)/
    # Fetch new targets to hit by ordering the nighboring tiles of hit targets
    # first use random targets if there aren't enough likely targets.
    shots = b.get_new_targets
    targets = (1..$1.to_i).map {
      target = shots.shift
      shots.push(target)
      target
    }
    puts "SHOTS #{targets[0..$1.to_i].join(' ')}"

  when /\AINFO SHOTS nithin\b/
    # Update the information about which tiles on the board have been hit
    # or missed.
    shot_status = line
    shot_status["INFO SHOTS nithin "] = ''
    b.update_hits_and_misses shot_status

  when /\AACTION FINISH\b/
    # Finish the game. No saving of gama data.
    puts "FINISH"
  end
end
