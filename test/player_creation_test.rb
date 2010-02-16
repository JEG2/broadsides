require "test_helper"

class TestPlayerCreation < Test::Unit::TestCase
  def teardown
    cleanup_player_files
  end
  
  def test_name_is_a_basename_minus_extension_of_the_file_path
    path = player("name", %Q{results.puts "Running..."})
    assert_equal(File.basename(path, ".rb"), Broadsides::Player.new(path).name)
    wait_for_results(/\ARunning...\Z/)  # give Ruby time to load
  end
  
  def test_you_can_write_to_the_process_running_inside_a_player
    path = player("name", %Q{results.puts gets})
    player = Broadsides::Player.new(path)
    player.puts "From test!"
    wait_for_results(/\AFrom test!\Z/)  # give Ruby time to load
  end
  
  def test_you_can_close_the_pipe_to_the_player_process
    path = player("name")
    player = Broadsides::Player.new(path)
    player.close
    assert_raise(IOError) do
      player.puts
    end
  end
end
