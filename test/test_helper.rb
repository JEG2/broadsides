require "test/unit"
require "pathname"
require "stringio"

require "broadsides"

module TestHelper
  TEST_DIR     = Pathname.new(__FILE__).dirname
  TEST_RESULTS = TEST_DIR + "test_results.txt"
  
  def player(name, player_program = "# do nothing\n")
    @players ||= [ ]
    @players <<  TEST_DIR + "#{name}.rb"
    @players.last.open("w") do |code|
      code.puts(<<-END_RUBY % [TEST_RESULTS.to_s, player_program])
      $stdout.sync = true
      open(%p, "a") do |results|
        results.sync = true
        %s
      end
      END_RUBY
      code.path
    end
  end
  
  def players(player_program = "# do nothing\n")
    (1..2).map { |n| player(n, player_program.gsub(/\bNAME\b/, n.to_s)) }
  end
  
  def wait_for_results(regexp, timeout = 5)
    start = Time.now
    loop do
      sleep 0.1
      results = TEST_RESULTS.read
      if results =~ regexp
        assert_match(regexp, results)
        break
      end
      if Time.now - start >= timeout
        fail "Timed out waiting for %p (saw %p)" % [regexp, results]
      end
    end
  end

  def cleanup_player_files
    TEST_RESULTS.unlink if TEST_RESULTS.exist?
    if defined? @players
      @players.each do |player|
        player.unlink if player.exist?
      end
      @players.clear
    end
  end
end
Test::Unit::TestCase.send(:include, TestHelper)
