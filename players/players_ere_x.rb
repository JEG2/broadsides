$stdout.sync = true

@name = File.basename(__FILE__, '.rb')

require File.expand_path('../../lib/eregon/player', __FILE__)

ARGF.each_line do |line|
  case line

  when /\AACTION SHIPS\b/
    # We have been asked to place our ships, so we send a valid response:
    ##puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
    puts @self.place_ships

  when /\AACTION SHOTS (\d)/
    shots = @self.shot!($1.to_i)
    puts shots

  when /\AACTION FINISH\b/
    # We don't save data, so we just need to tell the server we are done:
    puts "FINISH"

  when /\AINFO SETUP players:(#{Player::NAME}),(#{Player::NAME}) board:(?:\d+)x(?:\d+) ships:((?:[0-9]+,?)+)/
    n1,n2=$1,$2
    @ships = $3.split(',')

    p1 = Player.new(n1)
    p2 = Player.new(n2)

    @self, @opp = [p1,p2].partition { |p| p.name == @name }.map { |p| p.first }


  when /\AINFO SHOTS (#{Player::NAME})((?: ?\w+\d+:(?:hit|miss))+)/
    player, shots = $1, $2.split(' ').map { |shot| shot.split(':') }
    shots.each do |shot|
      [@self, @opp].find { |p| p.name == player }.fire(*shot)
    end

  when /\AINFO WINNER (#{Player::NAME})/
    
  end
end
