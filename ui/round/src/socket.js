module.exports = function(opts) {

    var send = opts.send;
    var controller = opts.ctrl;

    var handlers = {
        "initialise" : function(data) {
            controller.updateRack(data.rack);
            controller.setPlayers(data.players);
            controller.setPlayerNumber(data.playerNumber);
            controller.setPlayerToMove(data.playerMove);
            controller.setTilesRemaining(data.tilesRemaining);
        },
        "playerBoardMove" : function(data) {
            var moveNumber = data.moveNumber;

            // If we've already been sent this move (e.g. while
            // initialising), ignore it
            if (moveNumber <= controller.data.lastMoveReceived)
                return;

            var placed = data.placed;
            var players = data.players;
            var tilesRemaining = data.tilesRemaining;
            controller.setPlayerToMove(data.nowPlaying);
            controller.boardMoveMade(placed);
            controller.setPlayers(players);
            controller.setTilesRemaining(tilesRemaining);
            controller.addBoardMoveToHistory(data.summary);

            controller.data.lastMoveReceived = moveNumber;
        },
        "playerExchangeMove" : function(data) {
            var moveNumber = data.moveNumber;

            // If we've already been sent this move (e.g. while
            // initialising), ignore it
            if (moveNumber <= controller.data.lastMoveReceived)
                return;

            controller.setPlayerToMove(data.nowPlaying);
            controller.addExchangeMoveToHistory();

            controller.data.lastMoveReceived = moveNumber;
        },
        "playerPassMove" : function(data) {
            var moveNumber = data.moveNumber;

            // If we've already been sent this move (e.g. while
            // initialising), ignore it
            if (moveNumber <= controller.data.lastMoveReceived)
                return;

            controller.setPlayerToMove(data.nowPlaying);
            controller.addPassMoveToHistory();

            controller.data.lastMoveReceived = moveNumber;
        },
        "gameFinished" : function(data) {
            if (data.placed) {
                controller.boardMoveMade(data.placed)
            }

            controller.setPlayers(data.summary.players);

            var boardMoveSummary = {
                "type" : "board",
                "overallScore" : data.summary.lastMoveScore,
                "wordsMade" : data.summary.wordsMade
            };

            controller.addBoardMoveToHistory(boardMoveSummary);
            controller.setPenalties(data.summary.penalties);
        },
        "boardMoveSuccess" : function(data) {
            var rack = data.rack;
            controller.updateRack(rack);
        },
        "exchangeMoveSuccess" : function(data) {
            var rack = data.rack;
            controller.updateRack(rack);
        },
        "playerChat" : function(data) {
            var playerName = data.player;
            var message = data.message;

            controller.addChatMessage(playerName, message);
        },
        "potentialScore" : function(data) {
            var potentialScore = data.potentialScore;
            controller.setPotentialScore(potentialScore);
        },
        "error" : function(data) {
            controller.showErrorMessage(data);
        }
    };

    var parseAndIssueCommand = function(command) {
        var commandName = command.command;

        var handler = handlers[commandName];

        if (handler) {
            handler(command.payload);
        }
        else
        {
            console.info("Unrecognised command: ");
            console.dir(command);
        }

        console.dir(command);
    }

    return {
        parseAndIssueCommand : parseAndIssueCommand
    }
}
