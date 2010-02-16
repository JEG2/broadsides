module Broadsides
  class Game
    def initialize(*players)
      options = players.last.is_a?(Hash) ? players.pop : { }
      @log    = options[:log]
      fail "Two players are required." unless players.size == 2
      @players = players.map { |path| Player.new(path) }
      catch(:over) do
        names = @players.map { |player| player.name }.join(",")
        inform(:SETUP, "players:#{names} board:10x10 ships:5,4,3,3,2")
        @players.each do |player|
          response = action(:SHIPS, "5,4,3,3,2", player)
          if response =~ /\ASHIPS(?: [2-5]:[A-L](?:10|[1-9]):[HV]){5}\z/
            placements = response.split[1..-1]
            unless placements.map { |ship| ship[/\A\d/] }.sort == %w[2 3 3 4 5]
              record_loss(player)
            end
            log("INFO SHIPS #{player.name} #{placements.join(' ')}")
            placements.each do |placement|
              length, location, direction = placement.split(":")
              begin
                player.place_ship(length.to_i, location, direction == "H")
              rescue RuntimeError
                record_loss(player)
              end
            end
          else
            record_loss(player)
          end
        end
      end
    end
    
    def run_one_turn
      catch(:over) do
        @players.each do |player|
          other    = other(player)
          response = action(:SHOTS, player.shots, player)
          if response =~ /\ASHOTS(?: [A-L](?:10|[1-9])){#{player.shots}}\z/
            results = response.split[1..-1].map { |shot|
              begin
                "#{shot}:#{other.hit?(shot) ? 'hit' : 'miss'}"
              rescue RuntimeError
                record_loss(player)
              end
            }
            inform(:SHOTS, "#{player.name} #{results.join(' ')}")
          else
            record_loss(player)
          end
          record_loss(other) if other.all_ships_sunk?
        end
      end
    end
    
    def run
      loop do
        break if winner
        run_one_turn
      end
    end
    
    def winner
      @players.find { |player| player.winner? }
    end
    
    def finish
      if w = winner
        inform(:WINNER, w.name, :dont_track_errors)
        @players.each do |player|
          action(:FINISH, nil, player, :dont_track_errors)
        end
      end
      @players.each do |player|
        player.close
      end
      @log.close if @log
      w.name if w
    end
    
    private
    
    def inform(kind, message, dont_track_errors = false)
      full_message = "INFO #{kind} #{message}"
      log full_message
      @players.each do |player|
        begin
          player.puts full_message
        rescue Exception
          record_loss(player) unless dont_track_errors
        end
      end
    end
    
    def action(kind, message, player, dont_track_errors = false)
      player.puts "ACTION #{kind} #{message}".strip
      player.gets.to_s.strip
    rescue Exception
      record_loss(player) unless dont_track_errors
    end
    
    def other(player)
      @players.first == player ? @players.last : @players.first
    end
    
    def record_loss(player)
      other(player).winner = true
      throw :over
    end
    
    def log(message)
      @log.puts message.sub(/\AINFO /, "") if @log
    end
  end
end
