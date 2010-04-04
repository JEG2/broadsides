# Dmitriy Nagirnyak (dnagir at gmail dot com) for
#  the Ruby Challenge 7 (Broadsides)
#  http://rubylearning.com/blog/2010/02/23/rpcfn-broadsides-7
require "enumerator"


# Add small helpers to the String for grid navigation
class String
  # Returns the x-coordinate which is the letter on the board (B in B5)
  def x(from = 0)
    self[0,1][0] - 65 + from # 65.chr = 'A'
  end
  
  # Returns the y-coordinate which is the number on the board (5 in B5)
  def y(from = 0)
    self[1,2].to_i - 1 + from
  end

  def to_up(default = nil)
    pos = y(1)
    return default if pos == 1
    self[0,1] + (pos - 1).to_s
  end
  
  def to_dn(default = nil)
    pos = y(1)
    return default if pos == 10
    self[0,1] + pos.succ.to_s
  end
  
  def to_left(default = nil)
    pos = x(65)
    return default if pos == 65
    (pos - 1).chr + self[1,2]
  end
  
  def to_right(default = nil)
    pos = x(65)
    return default if pos == 74 # 'J'
    pos.succ.chr + self[1,2]
  end
end


# Just want to navigate to any side as much as I want with no worries: "A1".to_left.to_left => nil
class NilClass
  def to_up(default = nil)
    default
  end
  def to_dn(default = nil)
    default
  end
  def to_left(default = nil)
    default
  end
  def to_right(default = nil)
    default
  end
end


# Discovers ships by shooting at positions 'strategically'.
# This ensures all ships will BE hit with minimal number of shots.
class ShipDiscovery
  def initialize(guide_option = nil)
    @guide = [
      5,2,1,4,1,5,1,4,3,1, # 0
      1,5,4,1,3,1,5,3,1,2, # 1
      2,4,5,2,1,4,1,5,2,4, # 2
      4,1,2,5,4,1,3,1,5,1, # 3
      1,3,1,4,5,2,1,4,1,5, # 4
      5,1,4,1,2,5,4,1,3,1, # 5
      1,5,1,3,1,4,5,2,1,4, # 6
      4,1,5,1,4,1,2,5,4,1, # 7
      1,3,1,5,1,3,1,4,5,2, # 8
      2,1,4,1,5,1,4,2,1,5 # 9
    ]
    
    guide_option = rand(5) if guide_option == :transform
    # Change the guide for discovery shots according one of rules
    @guide = case guide_option
      when 1
        @guide.reverse # Reverse the whole sequence
      when 2
        (0..9).map do |l|
           @guide[l*10, 10].reverse
         end.flatten # Reverse horizontally
      when 3
        (0..9).map do |col|
           (0..9).map { |l| @guide[l*10 + col] }.reverse
         end.flatten # Rotate right
      when 4
        (0..9).map do |col|
           (0..9).map { |l| @guide[l*10 + col] }
         end.reverse.flatten # Transpose
      else @guide
    end
  end  
  
  def next
    # Find the maximum element    
    ship_size = @guide.reject { |p| p == nil }.max || 0    
    available_positions = @guide.enum_with_index.map { |p,i| p == ship_size ? i : nil }.compact
    return nil if available_positions.empty?
    next_pos = available_positions[rand(available_positions.length)]
    @guide[next_pos] = nil # Do not shot here anymore, been already    
    to_location next_pos    
  end
    
  private
    
  def to_location(pos)
    "#{(pos % 10 + 65).chr}#{pos / 10 + 1}"
  end
end

# The player itslef
class Player
  attr_accessor :field
  
  def initialize
    @discovery = ShipDiscovery.new(:transform)
    @field = {}
    @shot_queue = []
  end
    
  # Returns the player name as used on the server
  def name
    File.basename(__FILE__, '.rb')
  end
      
  def shootable?(here)
    return false unless here
    # there are MISSes all around - cannot be the target
    # Do not take into account out-of-bounds
    around = [here.to_left, here.to_right, here.to_up, here.to_dn].reject { |l| l.nil? }
    around = around.map { |l| field[l] } # from locations to the values
    return false if !around.empty? && around.all? { |l| l == :miss }
    field[here].nil?
  end
  
  # Returns next position from the sequence to shot at. Examples: A1, B10, J9
  def next_target
    # First shot at the priority positions
    begin
      here = @shot_queue.shift
    end while !shootable?(here) && !@shot_queue.empty?
    # Then shot according to ship discovery
    while !shootable?(here) do
      here = @discovery.next
      break if here.nil?
    end    
    field[here] = :shot if here
    here
  end
  
  # Returns ships' positions as per server. Includes only the actual positions with no message.
  def allocate_ships
    options =[
     "5:A1:V 4:J5:V 3:A8:H 3:I1:V 2:!?:H".sub('!', ('C'..'G').sort_by { rand }.first).sub('?', (1..9).sort_by{ rand }.first.to_s),
     "5:I1:V 4:H6:V 3:E10:H 3:D7:V 2:!?:V".sub('!', ('A'..'G').sort_by { rand }.first).sub('?', (1..4).sort_by{ rand }.first.to_s),
     "5:E3:V 4:A2:V 3:A7:V 3:J5:V 2:!?:V".sub('!', ('G'..'I').sort_by { rand }.first).sub('?', (1..9).sort_by{ rand }.first.to_s),
     "5:F10:H 4:A10:H 3:A2:V 3:H1:H 2:!?:H".sub('!', ('C'..'I').sort_by { rand }.first).sub('?', (3..8).sort_by{ rand }.first.to_s),
     "5:B1:H 4:J2:V 3:J7:V 3:F10:H 2:A?:V".sub('?', (rand(8)+2).to_s),
     "5:F6:H 4:D5:V 3:E4:H 3:F9:H 2:!1:H".sub('!', (rand(9)+65).chr),
     "5:F10:H 4:B1:H 3:A2:V 3:A6:V 2:J?:V".sub('?', (rand(7)+1).to_s),
     "5:F1:V 4:A6:H 3:H6:H 3:F8:V 2:!?:V".sub('!', ['A','B','C','H','I','J'][rand(6)]).sub('?', [1,2,8,9][rand(4)].to_s),     
    ]
    options[rand(options.length)]
  end
  
  # Receives count
  # Returns space delimited positions. Such as "A1 J10"
  def shot(count)
    shots = (1..count).map do
      next_target || 'A1' # Out of shots already, just satisfy min-shots requirement
    end * ' '
    shots
  end
  
  # Expecting string: "A1:hit B10:miss"
  # Processes the result, marks the field appropriately, changes the sequence of shots accordingly.
  def process_shot_result(shot_result)
    shot_result.split(/:|\s/).each_slice(2) do |location, result|
      field[location] = result.to_sym      
      has_hit(location) if field[location] == :hit
    end
  end
  
  # Callback for an on-target shot
  def has_hit(hit)
    asap = []
    asap.push hit.to_left,  hit.to_left.to_left     if field[hit.to_right] == :hit
    asap.push hit.to_right, hit.to_right.to_right   if field[hit.to_left] == :hit
    asap.push hit.to_up,    hit.to_up.to_up         if field[hit.to_dn] == :hit
    asap.push hit.to_dn,    hit.to_dn               if field[hit.to_up] == :hit
    if asap.empty?
      # Force shooting around
      asap = [ hit.to_left,
        hit.to_right,
        hit.to_up,
        hit.to_dn
      ].reject { |l| l.nil? }      
    end
    asap.each { |l| @shot_queue.push l }
  end
end

# 
# This line, required by the rules, ensures the server sees our responses as
# soon as they are written.
# 
$stdout.sync = true

me = Player.new

# The main loop
ARGF.each_line do |line|
  case line
  when /\AACTION SHIPS\b/
    puts "SHIPS #{me.allocate_ships}"
  when /\AACTION SHOTS (\d)/
    puts 'SHOTS ' + me.shot($1.to_i)
  when /\AINFO SHOTS (\w+) (.+)/
    if $1 == me.name
      me.process_shot_result $2
    end
  when /\AACTION FINISH\b/
    puts "FINISH"
  end
end
