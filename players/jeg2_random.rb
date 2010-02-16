$stdout.sync = true

shots = (1..10).map { |y| ("A".."L").map { |x| "#{x}#{y}" } }.flatten.
                                                              sort_by { rand }

ARGF.each_line do |line|
  case line
  when /\AACTION SHIPS\b/
    puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
  when /\AACTION SHOTS (\d)/
    targets = (1..$1.to_i).map {
      target = shots.shift
      shots.push(target)
      target
    }
    puts "SHOTS #{targets.join(' ')}"
  when /\AACTION FINISH\b/
    puts "FINISH"
  end
end
