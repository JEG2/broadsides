# mod.rb
module Mod
  POS = [40, 360]
  RPOS = POS.reverse

  def read_game_log
    file = ask_open_file
    file ||= '../log/last_game.log'
    IO.readlines(file).each do |line|
      key, *log = line.split
      case key
      when /SETUP/
        @players = log.first.split(':').last.split(',')
      when /SHIPS/
        @ships ||= []; log.shift; @ships << log
      when /SHOTS/
        @shots ||= []; log.shift; @shots << log
      when /WINNER/
        @winner = log.first
      else
        error 'invarid game log...'
      end
    end
  end

  def start_battle
    POS.each_with_index do |x, i|
      caption @players[i], :left => x, :top => 10, :stroke => forestgreen, :weight => 'bold'
    end
    show_ships
    make_bombs
    show_battle
  end

  def show_ships
    @ships.each_with_index do |ships, i|
      ships.each do |ship|
        len, pos, hv = ship.split ':'
        hv == 'H' ? (x, y = len.to_i, 1) : (x, y = 1, len.to_i)
        l, t = convert pos
        image 'ship.gif', :width => 30*x, :height => 30*y, :left => POS[i]+30*l, :top => 50+30*t
      end
    end
    @bgs[1].style :fill => rand_color
  end

  def make_bombs
    @bombs = []
    @shots.each_with_index do |shots, i|
      shots.each do |shot|
        pos, hm = shot.split ':'
        l, t = convert pos
        img = hm == 'hit' ? 'fire.gif' : 'bomb.gif'
        @bombs << image(img, :width => 30, :height => 30, :left => RPOS[i%2]+30*l, :top => 50+30*t).hide
      end
      @bombs << 2
    end
    @times = @bombs.length - 1
  end

  def show_battle
    e = every do |i|
      @bombs[i] == 2 ? change_focus : @bombs[i].show
      if i == @times
        e.stop
        show_winner
      end
    end
  end

  def show_winner
    @players.each do |player|
      stack :width => 500, :height => 340, :left => 100, :top => 30 do
        background rgb(240, 230, 140, 0.7), :curve => 30
        subtitle "\n    WINNER:", :stroke => green
        para
        title @winner, :align => 'center', :stroke => deeppink, :weight => 'bold' 
      end
    end
  end

  def change_focus
    @bgs.each { |bg|
      bg.style[:fill] == white ? (bg.style :fill => rand_color) : (bg.style :fill => white)
    }
    sleep 2
  end

  def convert pos
    l, t = pos[0, 1], pos[1..-1]
    [('A'..'J').to_a.index(l), t.to_i - 1]
  end

  def rand_color
    rgb(rand(255), rand(255), rand(255), 0.5)..rgb(rand(255), rand(255), rand(255), 0.5)
  end
end
