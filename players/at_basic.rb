# Entry for RPCFN #7: Broadsides
# Challenge is to create a Broadsides (Battleships) AI which will defeat the
# other entrants. 
#
# This is my first entry, called BASIC (at_basic.rb) by Antonio Trogi

class String
  def prev
    25.times do
      self.next!
    end
    self.split('').last.to_s
  end
end

class Fixnum
  def prev
    self - 1
  end
end

# Initializer and parser class. Does all functionality and commands.
class BroadsidesCreator
  
  # creates all the necessary arrays for the parser.
  def initialize
   # This list of all map coordinates.
    @grid = (1..10).map { |y| ("A".."J").map { |x| "#{x}#{y}" } }.flatten
    # Define the boards perimeter coordinates (bottom, right) for ship placement.
    @perimeter = []
    @perimeter << @grid.map { |c| c if c =~ /J/ }.compact
    @perimeter << @grid.map { |c| c if c =~ /10/ }.compact
    @perimeter.flatten!
    @ships = []
    # The default number of ships and sizes given. Create valid starting points.
    [5, 4, 3, 3, 2].each do |size|
      add_ship(size)
    end
    @total_hits   = []
    @total_misses = []
    @all_shots    = []
    @next_round   = []
  end

  # Spits out the starting points and alignment for the ships.
  def ships_starting_points
    starts = "SHIPS "
    @ships.each do |ship|
      align = ship.first[0] == ship.last[0] ? "V" : "H"
      starts << "#{ship.size}:#{ship.first}:#{align} "
    end
    starts
  end
  
  # Spits out the next round of shots to the game.
  def shout_next_shots(shots)
    # If there are no predicted next shots, fill the array with randoms.
    until @next_round.size >= shots
      ary = @grid - (@all_shots + @next_round)
      @next_round << ary.sort_by{rand}.shift
    end
    targets = []
    # grab the first (oldest) shots in the array and fire away!
    shots.times { targets << @next_round.shift }
    "SHOTS #{targets.join(' ')}"
  end
  
  # Parses the incoming line and add the coordinates to their respective arrays.
  def new_line(line)
    line.scan(/[A-Z][0-9]+:\w+/).each do |result|
      coord = result.scan(/[A-Z][0-9]+/).to_s
      /hit/.match(result) ? @total_hits << coord : @total_misses << coord
    end
    # Add all the shots into the total array.
    @all_shots << @total_hits 
    @all_shots << @total_misses
    @all_shots.flatten!
    calculate_next_shots
  end
  
  private 
  
  # SHOT PLACEMENT METHODS #
  # 1. If there is a fresh hit
  # 2. There is no SUNK info, so keep tactic up until no hits, then go random
  def calculate_next_shots
    @total_hits.each do |hit|
      surrounds = find_surrounding_coords(hit)
      if @total_hits.include?(surrounds)
        # Create array of hits and add to either end then add to next shots.
        @next_round << surrounds
      else
        # Dump all the surrounding shots into the cannon for next round fire.
        @next_round << surrounds
      end
    end
    # Clean up the next round of shots by removing them if they 
    # are already locations that have been fired or queued.
    @next_round.flatten!
    @next_round.uniq!
    @next_round.delete_if { |c| @all_shots.include?(c) }
    # Clear out the hits, for the next round to come in.
    @total_hits.clear
  end
  
  # find the surrounding coords based on location. Cannot refrence coords outside
  # the grid. Must be this long and ugly to not break the rule of outside reference!
  def find_surrounding_coords(hit)
    case hit
    when /A1/
      [ hit.gsub(/([A-Z])/)  { $1.next },
        hit.gsub(/([0-9]+)/) { $1.next } ]
    when /A10/
      [ hit.gsub(/([A-Z])/)  { $1.next },
        hit.gsub(/([0-9]+)/) { $1.prev } ]
    when /J1/
      [ hit.gsub(/([A-Z])/)  { $1.prev },
        hit.gsub(/([0-9]+)/) { $1.next } ]
    when /J10/
      [ hit.gsub(/([A-Z])/)  { $1.prev },
        hit.gsub(/([0-9]+)/) { $1.prev } ]
    when /A/
      [ hit.gsub(/([A-Z])/)  { $1.next },
        hit.gsub(/([0-9]+)/) { $1.next },
        hit.gsub(/([0-9]+)/) { $1.to_i.prev.to_s } ]
    when /J/
      [ hit.gsub(/([0-9]+)/) { $1.next },
        hit.gsub(/([A-Z])/)  { $1.prev },
        hit.gsub(/([0-9]+)/) { $1.to_i.prev.to_s } ]
    when /1$/
      [ hit.gsub(/([A-Z])/)  { $1.next },
        hit.gsub(/([0-9]+)/) { $1.next },
        hit.gsub(/([A-Z])/)  { $1.prev } ]
    when /10/
      [ hit.gsub(/([A-Z])/)  { $1.next },
        hit.gsub(/([A-Z])/)  { $1.prev },
        hit.gsub(/([0-9]+)/) { $1.to_i.prev.to_s } ]
    else
      [ hit.gsub(/([A-Z])/)  { $1.next },
        hit.gsub(/([0-9]+)/) { $1.next },
        hit.gsub(/([A-Z])/)  { $1.prev },
        hit.gsub(/([0-9]+)/) { $1.to_i.prev.to_s } ]
    end
  end
  
  # SHIP PLACEMENT METHODS #
  # recursivly will add the ship to the grid until it does not collide with anyting.
  def add_ship(size)
    # Pick a random starting point (for now) and calculate where the ship will lie
    ship = calculate_coords(@grid.sort_by{rand}.first, size)
    if ship_collision?(ship)
      add_ship(size)
    else
      @ships << ship
    end
  end

  # creates the entire placement of the ship in question
  def calculate_coords(start, size)
    ship = [start]
    alignment = rand(2)  # 0 is horizontal, 1 is vertical 
    (size - 1).times do  # because the start position counts as 1 space.
      if alignment == 0
        ship << ship.last.gsub(/([A-Z])/) { $1.next }
      else
        ship << ship.last.gsub(/(\d+)/)   { $1.next }
      end
    end
    ship
  end

  # checks weather placement of a ship collides with either another ship or edge.
  def ship_collision?(ship)
    ship.each do |coor|
      return true if @perimeter.include?(coor) or @ships.flatten.include?(coor)
    end
    false
  end
  
end

@parser = BroadsidesCreator.new

# This line ensures the server sees our responses as soon as they are written.
$stdout.sync = true

# This loop reads messages from the server, one line at a time.
ARGF.each_line do |line|
  case line
  when /\AACTION SHIPS\b/
    # We have been asked to place our ships, so we send a valid response:
    puts @parser.ships_starting_points
  when /\AACTION SHOTS (\d)/
    # We fire the requested number of shots:
    puts @parser.shout_next_shots($1.to_i)
  when /\AACTION FINISH\b/
    # We don't save data, so we just need to tell the server we are done:
    puts "FINISH"
  when /\AINFO SHOTS\b/
    # Only care about weather our shots hit or missed.
    @parser.new_line(line) if /at_basic/.match(line)
  end
end