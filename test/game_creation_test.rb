require "test_helper"

class TestGameCreation < Test::Unit::TestCase
  def teardown
    cleanup_player_files
  end
  
  def test_a_game_requires_two_players
    [0, 1, 3, 4].each do |count|
      assert_raise(RuntimeError) do
        Broadsides::Game.new(*(1..count).map { |n| player(n) })
      end
    end
  end
  
  def test_a_game_will_execute_both_player_files_as_ruby_programs
    players = players(%Q{results << "NAME executed\n"})
    game    = Broadsides::Game.new(*players)
    wait_for_results( / \A (?: 1\sexecuted\n2\sexecuted\n |
                               2\sexecuted\n1\sexecuted\n ) \z /x )
  ensure
    game.finish if game
  end
  
  def test_a_new_game_sends_a_setup_message_to_both_players
    players = players(%q{results.puts "#{Process.pid} #{gets}"})
    game    = Broadsides::Game.new(*players)
    wait_for_results( / \A (?: \d+\sINFO\sSETUP
                                  \splayers:1,2
                                  \sboard:10x10
                                  \sships:5,4,3,3,2\n ){2} \z /x )
  ensure
    game.finish if game
  end
end
