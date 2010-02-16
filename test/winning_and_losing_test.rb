require "test_helper"

class TestWinningAndLosing < Test::Unit::TestCase
  def teardown
    cleanup_player_files
  end
  
  def test_both_players_are_notified_of_winner_when_a_game_ends
    players = [player(1, <<-'END_PLAYER1'), player(2, <<-'END_PLAYER2')]
    shots   = ["A1 B1 C1 D1 E1 A2", "B2 C2 D2 A3 B3 C3", "A4 B4 C4 A5 B5 C5"]
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS \d\Z/
        puts "SHOTS #{shots.shift}"
      elsif line =~ /\AINFO WINNER \d\Z/
        results.puts "1: #{line}"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_PLAYER1
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        puts "SHOTS #{(%w[A1] * $1.to_i).join(' ')}"
      elsif line =~ /\AINFO WINNER \d\Z/
        results.puts "2: #{line}"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_PLAYER2
    game = Broadsides::Game.new(*players)
    game.run
    game.finish
    wait_for_results(/ \A (?: 1:\sINFO\sWINNER\s1\n2:\sINFO\sWINNER\s1\n |
                              2:\sINFO\sWINNER\s1\n1:\sINFO\sWINNER\s1\n )
                       \z /x )
  end
  
  def test_both_players_given_a_chance_to_finish
    players = [player(1, <<-'END_PLAYER1'), player(2, <<-'END_PLAYER2')]
    shots   = ["A1 B1 C1 D1 E1 A2", "B2 C2 D2 A3 B3 C3", "A4 B4 C4 A5 B5 C5"]
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS \d\Z/
        puts "SHOTS #{shots.shift}"
      elsif line =~ /\AACTION FINISH\Z/
        results.puts "1 finishing"
        puts "FINISH"
      end
    end
    END_PLAYER1
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        puts "SHOTS #{(%w[A1] * $1.to_i).join(' ')}"
      elsif line =~ /\AACTION FINISH\Z/
        results.puts "2 finishing"
        puts "FINISH"
      end
    end
    END_PLAYER2
    game = Broadsides::Game.new(*players)
    game.run
    game.finish
    wait_for_results(/ \A (?: 1\sfinishing\n2\sfinishing\n |
                              2\sfinishing\n1\sfinishing\n ) \z /x )
  end
  
  def test_a_player_who_stops_responding_loses
    assert_loses(%Q{exit})
  end
  
  def test_a_player_responding_with_a_malformed_ships_line_loses
    assert_loses(<<-'END_RUBY')
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS MALFORMED"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        puts "SHOTS #{(%w[A1] * $1.to_i).join(' ')}"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_RUBY
  end
  
  def test_a_player_who_tries_to_place_the_wrong_ships_loses
    assert_loses(<<-'END_RUBY')
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 5:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        puts "SHOTS #{(%w[A1] * $1.to_i).join(' ')}"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_RUBY
  end
  
  def test_a_player_who_tries_to_place_a_ship_out_of_column_bounds_loses
    assert_loses(<<-'END_RUBY')
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:M5:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        puts "SHOTS #{(%w[A1] * $1.to_i).join(' ')}"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_RUBY
  end
  
  def test_a_player_who_tries_to_place_a_ship_out_of_row_bounds_loses
    assert_loses(<<-'END_RUBY')
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A11:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        puts "SHOTS #{(%w[A1] * $1.to_i).join(' ')}"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_RUBY
  end
  
  def test_a_player_who_tries_to_place_ships_on_top_of_each_other_loses
    assert_loses(<<-'END_RUBY')
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:E1:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        puts "SHOTS #{(%w[A1] * $1.to_i).join(' ')}"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_RUBY
  end
  
  def test_a_player_responding_with_a_malformed_shots_line_loses
    assert_loses(<<-'END_RUBY')
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS \d\Z/
        puts "SHOTS MALFORMED"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_RUBY
  end
  
  def test_a_player_who_tries_takes_too_few_shots_loses
    assert_loses(<<-'END_RUBY')
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        puts "SHOTS #{(%w[A1] * ($1.to_i - 1)).join(' ')}"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_RUBY
  end
  
  def test_a_player_who_tries_takes_too_many_shots_loses
    assert_loses(<<-'END_RUBY')
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        puts "SHOTS #{(%w[A1] * ($1.to_i + 1)).join(' ')}"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_RUBY
  end
  
  def test_a_player_who_tries_to_shoot_out_of_column_bounds_loses
    assert_loses(<<-'END_RUBY')
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS \d\Z/
        puts "SHOTS A1 A1 A1 A1 A1 M1"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_RUBY
  end
  
  def test_a_player_who_tries_to_shoot_out_of_row_bounds_loses
    assert_loses(<<-'END_RUBY')
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS \d\Z/
        puts "SHOTS A1 A1 A1 A1 A1 A11"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_RUBY
  end
  
  private
  
  def assert_loses(loser_code)
    game = Broadsides::Game.new( player("loser", loser_code),
                                 player("winner", <<-'END_RUBY') )
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        puts "SHOTS #{(%w[A1] * $1.to_i).join(' ')}"
      elsif line =~ /\AINFO WINNER (\w+)\Z/
        results.puts $1
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_RUBY
    game.run
    game.finish
    wait_for_results(/\Awinner\n\z/)
  end
end
