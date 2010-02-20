# broadsides_battle_viewer.rb
require 'mod'

Shoes.app title: 'Battle Viewer r0.1 for JEG2 broadsides', width: 700, height: 400 do
  extend Mod
  @bgs = []
  POS.each do |x|
    @bgs << rect(x, 50, 300, 300, stroke: blue, fill: white, )
    9.times{|i| line x, 80+30*i, x+300, 80+30*i, stroke: blue}
    9.times{|i| line x+30*(i+1), 50, x+30*(i+1), 350, stroke: blue}
  end
  
  para link('read log'){read_game_log; @sb.show}, left: 40, top: 360
  @sb = para(link('start battle'){start_battle}, left: 150, top: 360).hide
end
