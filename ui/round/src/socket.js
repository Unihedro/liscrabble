module.exports = function(opts) {

    var send = opts.send;
    var controller = opts.ctrl;

    var handlers = {
        "playerBoardMove" : function(data) {
            var placed = data.placed;
            var players = data.players;
            var tilesRemaining = data.tilesRemaining;
            controller.setPlayerToMove(data.nowPlaying);
            controller.boardMoveMade(placed);
            controller.setPlayers(players);
            controller.setTilesRemaining(tilesRemaining);
            controller.addBoardMoveToHistory(data.summary);
        },
        "playerExchangeMove" : function(data) {
            controller.setPlayerToMove(data.nowPlaying);
            controller.addExchangeMoveToHistory();
        },
        "playerPassMove" : function(data) {
            controller.setPlayerToMove(data.nowPlaying);
            controller.addPassMoveToHistory();
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
