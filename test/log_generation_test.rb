require "test_helper"

class TestLogGeneration < Test::Unit::TestCase
  def teardown
    cleanup_player_files
  end
  
  def test_a_log_can_be_generated_of_game_info_messages_plus_ship_placements
    logger = player("logger", <<-'END_RUBY')
    shots  = ["A1 B1 C1 D1 E1 A2", "B2 C2 D2 A3 B3 C3", "A4 B4 C4 A5 B5 C5"]
    ARGF.each do |line|
      if line =~ /\AINFO (.+)\Z/
        results.puts $1
      end
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS \d\Z/
        puts "SHOTS #{shots.shift}"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_RUBY
    loser = player("loser", <<-'END_RUBY')
    ARGF.each do |line|
      if line == "ACTION SHIPS 5,4,3,3,2\n"
        puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
      elsif line =~ /\AACTION SHOTS (\d)\Z/
        puts "SHOTS #{(%w[A1] * $1.to_i).join(' ')}"
      elsif line =~ /\AACTION FINISH\Z/
        puts "FINISH"
      end
    end
    END_RUBY
    log  = StringIO.new
    game = Broadsides::Game.new(logger, loser, :log => log)
    game.run
    game.finish
    wait_for_results(/^WINNER \w+\n\z/)
    setup, *play = TEST_RESULTS.read.split("\n").map { |s| Regexp.escape(s) }
    ships        = [logger, loser].map { |n|
      "SHIPS #{File.basename(n, '.rb')} 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H\n"
    }
    assert_match(/\A#{setup}\n#{ships}#{play.join("\n")}\n\z/, log.string)
  end
end
