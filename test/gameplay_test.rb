require "test_helper"

class TestGameplay < Test::Unit::TestCase
  def teardown
    cleanup_player_files
  end
  
  def test_players_are_asked_to_place_ships_in_turn
    game = Broadsides::Game.new(*players(<<-'END_RUBY'))
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        results.puts "NAME asked for SHIPS."
        puts         "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      end
    end
    END_RUBY
    wait_for_results(/\A1 asked for SHIPS.\n2 asked for SHIPS.\n\z/)
  ensure
    game.finish if game
  end
  
  def test_players_take_shots_in_turns
    game = Broadsides::Game.new(*players(<<-'END_RUBY'))
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        results.puts "NAME asked for SHOTS."
        puts "SHOTS #{(%w[A1] * $1.to_i).join(' ')}"
      end
    end
    END_RUBY
    game.run_one_turn
    wait_for_results(/\A1 asked for SHOTS.\n2 asked for SHOTS.\n\z/)
  ensure
    game.finish if game
  end
  
  def test_both_players_are_notified_of_shot_results
    game = Broadsides::Game.new(*players(<<-'END_RUBY'))
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        puts "SHOTS A1 A2 A3 A4 A5 A6"
      elsif line =~ /\AINFO SHOTS (\d)(?: [A-L](?:10|[1-9]):(?:hit|miss)){6}\Z/
        results.puts "NAME: #{line}"
      end
    end
    END_RUBY
    game.run_one_turn
    results1 = ":\\sINFO\\sSHOTS\\s1\\s" +
               "A1:hit\\sA2:hit\\sA3:hit\\sA4:hit\\sA5:hit\\sA6:miss\\n"
    results2 = results1.sub("1", "2")
    wait_for_results(/ \A (?: 1#{results1}2#{results1} |
                              2#{results1}1#{results1} )
                          (?: 1#{results2}2#{results2} |
                              2#{results2}1#{results2} ) \z /x )
  ensure
    game.finish if game
  end
  
  def test_losing_a_ship_costs_you_a_shot
    players = [player(1, <<-'END_PLAYER1'), player(2, <<-'END_PLAYER2')]
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        results.puts "SHOTS:  #{$1}"
        puts "SHOTS #{(%w[A1] * $1.to_i).join(' ')}"
      end
    end
    END_PLAYER1
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS \d\Z/
        puts "SHOTS A2 B2 C2 D2 E2 F2"
      end
    end
    END_PLAYER2
    game = Broadsides::Game.new(*players)
    2.times do
      game.run_one_turn
    end
    wait_for_results(/\ASHOTS:  6\nSHOTS:  5\n\z/)
  ensure
    game.finish if game
  end
  
  def test_losing_the_length_five_ship_costs_you_a_shot
    players = [player(1, <<-'END_PLAYER1'), player(2, <<-'END_PLAYER2')]
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        results.puts "SHOTS:  #{$1}"
        puts "SHOTS #{(%w[A1] * $1.to_i).join(' ')}"
      end
    end
    END_PLAYER1
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS \d\Z/
        puts "SHOTS A1 B1 C1 D1 E1 F1"
      end
    end
    END_PLAYER2
    game = Broadsides::Game.new(*players)
    2.times do
      game.run_one_turn
    end
    wait_for_results(/\ASHOTS:  6\nSHOTS:  4\n\z/)
  ensure
    game.finish if game
  end
  
  def test_run_ends_when_a_player_has_all_ships_sunk
    players = [player(1, <<-'END_PLAYER1'), player(2, <<-'END_PLAYER2')]
    shots   = ["A1 B1 C1 D1 E1 A2", "B2 C2 D2 A3 B3 C3", "A4 B4 C4 A5 B5 C5"]
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS \d\Z/
        results.puts "1 shooting"
        puts "SHOTS #{shots.shift}"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_PLAYER1
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        results.puts "2 shooting"
        puts "SHOTS #{(%w[A1] * $1.to_i).join(' ')}"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_PLAYER2
    game = Broadsides::Game.new(*players)
    game.run
    wait_for_results(/\A(?:1 shooting\n2 shooting\n){2}1 shooting\n\z/)
  ensure
    game.finish if game
  end
end
