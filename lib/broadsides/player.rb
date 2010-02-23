require "rbconfig"
require "timeout"

module Broadsides
  class Player
    RUBY_EXE = File::join( *Config::CONFIG.
                            values_at(*%w[bindir ruby_install_name]) ) <<
               Config::CONFIG["EXEEXT"]
    WINDOWS  = Config::CONFIG["host_os"] =~ /mswin|mingw/
    
    def initialize(path)
      @name   = File.basename(path, ".rb")
      @board  = { }
      @ships  = [ ]
      @winner = false
      @pipe   = open("| #{shell_escape RUBY_EXE} #{shell_escape path}", "r+")
    rescue Exception => error
      fail "Player %p could not be opened:  %s" % [path, error.message]
    end
    
    attr_reader :name
    attr_writer :winner
    
    def puts(*args)
      @pipe.puts(*args)
    end

    def gets(*args)
      Timeout.timeout(60) { @pipe.gets(*args) }
    end
    
    def close
      @pipe.close
    end
    
    def place_ship(length, location, horizontal)
      @ships << [ ]
      length.times do |offset|
        coords = move(location, offset, horizontal)
        fail "Location already taken" unless @board[coords].nil?
        @board[coords] =  true
        @ships.last << coords
      end
    end
    
    def shots
      @ships.inject(0) { |shots, ship|
        shots + (ship.any? { |c| @board[c] } ? (ship.length == 5 ? 2 : 1) : 0)
      }
    end
    
    def hit?(location)
      shot             =  @board[location]
      @board[location] =  false if shot
      shot             != nil
    end
    
    def all_ships_sunk?
      not @board.values.any?
    end
    
    def winner?
      @winner
    end
    
    private
    
    def shell_escape(string)
      string.gsub(/(?=[^a-zA-Z0-9_.\/\-#{':' if WINDOWS}\x7F-\xFF\n])/n, '\\').
             gsub(/\n/, "'\n'").
             sub(/\A\z/, "''")
    end
    
    def move(where, plus, horizontal)
      x  = where[/[A-J]/].unpack('c')[0] # Made 1.8-9 compatible
      y  = where[/10|[1-9]/].to_i
      to = horizontal ? "#{(x + plus).chr}#{y}" : "#{x.chr}#{y + plus}"
      fail "Out of bounds" unless to =~ /\A[A-J](?:10|[1-9])\z/
      to
    end
  end
end
