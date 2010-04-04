$stdout.sync = true

class Battleships

  def initialize
    @@last = [1,1]
    @@smallest = 2
    @@shots = []
    @@hits=[]
    @@alph=[0,"A", "B", "C", "D","E","F","G","H","I","J"]
    @@q=[]
  end
  
  def proceed
    new=[]
    shots=[]
    g = @@smallest
    new = [(@@last[0]+g),(@@last[1])]
    if new[0] >10
      new[1]+=1
      new[0]=(new[0]%10 - (g+1)%2)
      if new[1] >10
        new= [1,1]
      end
    end
    if new[0]<=0
      new[0]+=g
    end
    @@last = new
    return new
  end

  def target
    i=@@hits.map{ |x|
      x=x.to_s.scan(/(.)/)
      x=[@@alph.index(x[0].to_s),x[1].to_s.to_i]
      }
      q=[]
    i.each{|x|
      q<<[x[0]+1,x[1]]<<[x[0],x[1]+1]<<[x[0]-1,x[1]]<<[x[0],x[1]-1]
      }
    q.delete_if{|x|
    x[0]<=0 or x[1]<=0 or x[0]>=11 or x[1]>=11 or @@shots.include?(x)
    }
    @@q=q
  end
  
  def shoot(n)
    target
    turn=[]
    for i in 1..n
      turn<<@@q.shift
    end
    turn.compact!
    n-=turn.length
    for i in 1..n
      turn<<proceed
    end
    turn.each{|x| @@shots<<x}
  return shot_message(turn)
end

  def shot_message(turn)
    text="SHOTS"
    turn.each{|x|
        text<<" "+@@alph[x[0]].to_s+x[1].to_s
      }
    return text
  end
  
  def placement (ships)
    @@ships = Array.new
    @@message = "SHIPS"
    ships.each_index { |x|
      s = ships[x]
      @@ships[x]=Array.new
      occupancy = false
      while occupancy == false
        construct(x,s)
        occupancy = check
      end
    }
    print
    return @@message
  end
  
  def check
    check = true
    buffer = 
    @@ships[-1].each { |y|
      @@ships[0 .. -2].each { |w|
        w[2 .. -1].each { |z|
        if y == z
          check = false
        end
        }
        }
    }
    return check
  end

  def construct(x,s)
    o = rand(2)
    v = rand(9 - (s*o))
    h = rand(9 + (s*(o-1)))
    @@ships[x] = Array.new
    if o == 1
      @@ships[x][1] = "V"
      else
        @@ships[x][1] = "H"
    end
      @@ships[x][0] = s
    for i in 2 .. s + 1
        @@ships[x][i] = [h - (i*(o-1)),v + (i*o)]
    end
  end
  
  def read(line)
    player=line.scan(/SHOTS (\S*)/).to_s
    if player=="pc_player"
      @@hits=line.scan(/(..):hit/)
    end
  end
  
  def print
    alph = ["A", "B", "C", "D","E","F","G","H","I","J"]
    @@ships.each { |x|
     x[2][0] = alph[x[2][0]]
     }
    @@ships.each { |x|
      @@message << " " + x[0].to_s + ":" + x[2][0].to_s + (x[2][1]+1).to_s + ":" + x[1]}
end

end

game = Battleships.new
ARGF.each_line do |line|
  case line
  when /\AACTION SHIPS\b/ 
    ships = line.scan(/SHIPS (.*)/ ).to_s.split(',').map! { |x| x = x.to_i}
    puts game.placement(ships)
  when /\AACTION SHOTS (\d)/
    puts game.shoot($1.to_i)
  when /\AINFO SHOTS\b/
    game.read(line)
  when /\AACTION FINISH\b/
    puts "FINISH"
  end
end

