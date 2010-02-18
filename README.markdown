Broadsides
==========

The game of Broadsides, perhaps more commonly known as _Battleship_, was played on pen and paper long before there was a commercial board game.  The game is very simple:

* Both players arrange ships of various length on their board where only they can see them
* Players take turns calling out shot coordinates and their opponent tells them if they have hit or missed a ship at those coordinates
* The first player to sink all of the opponent's ships is the winner

There are some minor variations to the game, mainly revolving around how many shots you get each turn.  For our purposes, we will say you receive one shot per ship, except for the biggest ship (length five) which gives you two shots.  You must declare all shots before you can learn which shots hit and which miss.

The Challenge
-------------

Create a player for the game of Broadsides.  Your goal is to make your player play better than all other submitted players.  All players will compete in a tournament with the winner claiming a prize.

The Tools
---------

I have provided a simple game engine, two weak players, and utility scripts for viewing the games in your browser and running a tournament.  You can [download these tools from Github](http://github.com/JEG2/broadsides).

The tools were developed with Ruby 1.8 and probably do not work properly with Ruby 1.9.  I have also not tested them on Windows as I use Unix.  I'm hopeful they will work there, but it's unconfirmed.  No external dependencies are required to use them, though the Rake gem, a Web browser that supports JavaScript, and an Internet connection are helpful.

Running a single game between two players is as easy as invoking the game script with the path to both player files.  Thus you can run a game with the two included players with the following command, assuming you are in the root directory of the project from Github:

    bin/broadsides players/jeg2_sequential.rb players/jeg2_random.rb

This will print who wins.  By default, it will also write a detailed game log to `log/last_game.log`.  If you would prefer to change the name of the log file (to keep them from writing over each other) you can add the `--log=NEW_NAME` option which would cause the file to be saved as `log/NEW_NAME.log`.  Just replace `NEW_NAME` with whatever you want to call the game.  You can also pass an empty name (`--log=`) to disable logging.

The log files are textual game details.  You can scan through this data or write scripts to process it.  I have included one such script to create a visual representation of the data that you can view in a Web browser.  This script should be passed the path to the log file you want to view and it will write a complete HTML page to `STDOUT`.  That means you could create an HTML representation of the default log file of a game with the following command:

    bin/log2html log/last_game.log > log/last_game.html

On Mac OS X, I can add one more detail to the end of that command open the file in my preferred browser after it is created:

    bin/log2html log/last_game.log > log/last_game.html; open log/last_game.html

The final tool included is the `bin/tournament` script we will use to judge the entries.  It doesn't require any arguments.  It runs a series of games where all players in the `players/` directory will play each other exactly ten times.  A player gets a point for each win and all players are ranked according to their total scores.

By default, the tournament script doesn't log the games, since it could be a lot of data.  If you would like to create a log file for each game though, just add the `--log` switch.

A convenience Rake task is provided to delete all log and html files currently in the `log/` directory:

    rake clear_logs

Building a Player
-----------------

The game engine communicates with player files using a simple CGI-like protocol.  Player files will be executed as Ruby programs.  While running, they will read data from the game server on `STDIN` and write their actions to the game server using `STDOUT`.  The game server can send two kinds of messages, `INFO`rmation messages about the game and `ACTION` requests when it is your player's turn to do something.

The following are examples of the three kinds of `INFO` messages the game server will send to your players:

    INFO SETUP players:jeg2_sequential,jeg2_random board:10x10 ships:5,4,3,3,2
    INFO SHOTS jeg2_sequential A1:hit B1:hit C1:hit D1:hit E1:hit F1:miss
    INFO WINNER jeg2_sequential

As you can see, the `SETUP` message tell you about the game.  This is the first message the server sends to both players.  The `board:` and `ships:` details are static is this version of the game and you are free to ignore them, but `players:` does list the players in the order they will move.

You will receive a `SHOTS` message after each player fires.  It gives the player's name followed by a list of their shots with notes for which `:hit` and which `:miss`ed.  You can see here that the game refers to X coordinates with the letters `A` through `J`.  Y coordinates are handled with the numbers `1` to `10`.  So `B4` is the square in the second column of the fourth row.  In other words, the board looks like this:

         +---+---+---+---+---+---+---+---+---+---+
         | A | B | C | D | E | F | G | H | I | J |
    +----+---+---+---+---+---+---+---+---+---+---+
    | 1  |   |   |   |   |   |   |   |   |   |   |
    +----+---+---+---+---+---+---+---+---+---+---+
    | 2  |   |   |   |   |   |   |   |   |   |   |
    +----+---+---+---+---+---+---+---+---+---+---+
    | 3  |   |   |   |   |   |   |   |   |   |   |
    +----+---+---+---+---+---+---+---+---+---+---+
    | 4  |   |   |   |   |   |   |   |   |   |   |
    +----+---+---+---+---+---+---+---+---+---+---+
    | 5  |   |   |   |   |   |   |   |   |   |   |
    +----+---+---+---+---+---+---+---+---+---+---+
    | 6  |   |   |   |   |   |   |   |   |   |   |
    +----+---+---+---+---+---+---+---+---+---+---+
    | 7  |   |   |   |   |   |   |   |   |   |   |
    +----+---+---+---+---+---+---+---+---+---+---+
    | 8  |   |   |   |   |   |   |   |   |   |   |
    +----+---+---+---+---+---+---+---+---+---+---+
    | 9  |   |   |   |   |   |   |   |   |   |   |
    +----+---+---+---+---+---+---+---+---+---+---+
    | 10 |   |   |   |   |   |   |   |   |   |   |
    +----+---+---+---+---+---+---+---+---+---+---+

The `WINNER` message is given as soon as one player sinks all of the opponents ships, or an opponent is disqualified for breaking a rule.  It contains the name of the winning player.

Additionally, the game can ask you for three different kinds of `ACTION`s.  The following are examples of those requests and the responses your player could send:

    ACTION SHIPS 5,4,3,3,2
    SHIPS 5:A1:H 4:A2:H 3:A3:H 3:A4:H 2:A5:V
    
    ACTION SHOTS 6
    SHOTS A1 B1 C1 D1 E1 F1
    
    ACTION FINISH
    FINISH

In the first command, the game server is requesting that you place the `SHIPS` of the indicated lengths.  Your response should be `SHIPS` followed by five groups of `LENGTH:TOP_LEFT_CORNER_OF_SHIP:H_OR_V` where `H_OR_V` stands for a horizontal or vertical placement.

The `SHOTS` request is the main command used during gameplay.  The game server includes how many shots you currently have and you will need to pay attention to that number, since it will decrease as you lose ships.  You return that number of targets.  The game server will then respond with the `INFO SHOTS` message we looked at earlier, telling you how those shots did.

The `FINISH` command is sent as the last act of the game server.  It allows you a chance to save date in accordance with the rules below before your process is terminated.

The Rules
---------

Your players must follow all of the rules listed below.  Any violation results in an instant loss of the game or a disqualification of your player from the tournament by the judges:

* You must create a player file with a name matching `/\A\w+\.rb\z/`
* You must use your initials at the start of your player file's name
* You may never load any libraries in your player that don't ship with Ruby
* You must run `$stdout.sync = true` in your player before talking to the server
* You must place the exact number and sizes of ships the server sends  
* You must place each ship length exactly one time
* You must not place a ship so any part of it extends off the board
* You may never reference a coordinate outside of the ranges A-J or 1-10
* You must always take exactly the number of shots the server sends
* You must respond to the `FINISH` request as described above
* You must correctly format all responses to the server as described above
* You must never take longer than 60 seconds to respond to a server request
* You may never attempt to affect the server or other players outside the game

Optionally, your player is allowed to save data to the disk, so it can learn as it plays and grow smarter.  This is why the `FINISH` command exists.  It gives you 60 seconds to save your data before the server shuts you down.  You are only allowed to save one file, it must have the same name as your player file but with a non-rb extension, it must be written to the same directory your player file is in, and the data saved cannot exceed 10 MB's.

See the included `jeg2_sequential.rb` for a minimal player that meets these rules.
