# 
# This line, required by the rules, ensures the server sees our responses as
# soon as they are written.
# 
$stdout.sync = true

# This list of all possible shots will be fired at in order
shots = (1..10).map { |y| ("A".."J").map { |x| "#{x}#{y}" } }.flatten

# This loop reads messages from the server, one line at a time.
ARGF.each_line do |line|
  case line
  when /\AACTION SHIPS\b/
    # We have been asked to place our ships, so we send a valid response:
    puts "SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:H"
  when /\AACTION SHOTS (\d)/
    # 
    # We fired the requested number of shots, careful to cycle the list so we
    # don't run out of targets in the finale turn:
    # 
    targets = (1..$1.to_i).map {
      target = shots.shift
      shots.push(target)
      target
    }
    puts "SHOTS #{targets.join(' ')}"
  when /\AACTION FINISH\b/
    # We don't save data, so we just need to tell the server we are done:
    puts "FINISH"
  # Obviously, you will also want to deal with INFO messages here...
  end
end
