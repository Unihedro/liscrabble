module Controllers.GameLobby.GameLobby (handleChannelMessage, handleJoinNewPlayer, handleLobbyFull) where

    import Prelude
    import Foundation
    import Control.Concurrent.STM.TVar
    import Controllers.GameLobby.Api
    import Controllers.Game.Model.ServerPlayer
    import Controllers.GameLobby.Api
    import Model.Api
    import Controllers.Game.Model.GameLobby
    import qualified Data.Text as T
    import Control.Concurrent.STM.TChan
    import Control.Monad
    import Control.Monad.STM
    import Control.Concurrent.STM.TVar
    import qualified Data.Map as M
    import Controllers.Game.Model.ServerGame
    import Controllers.Game.Api

    handleChannelMessage :: LobbyMessage -> LobbyResponse
    handleChannelMessage (PlayerJoined serverPlayer) = Joined serverPlayer
    handleChannelMessage (LobbyFull gameId) = StartGame gameId

    {-
        Creates a new player, adds them to the lobby, notifying the players
        of the new arrival via the broadcast channel and returns the new player.
    -}
    handleJoinNewPlayer :: App -> T.Text -> TVar GameLobby -> STM (ServerPlayer, Maybe ServerGame)
    handleJoinNewPlayer app gameId gameLobby =
        do
            lobby <- readTVar gameLobby
            newPlayerIdGenerator <- readTVar $ playerIdGenerator lobby
            let (playerId, newGen) = makeNewPlayerId newPlayerIdGenerator
            writeTVar (playerIdGenerator lobby) newGen

            let players = lobbyPlayers lobby
            let newPlayerName =  T.concat ["player", T.pack . show $ (length players + 1)]
            let newPlayer = makeNewPlayer newPlayerName playerId
            let newPlayers = players ++ [newPlayer]
            let newLobby = updatePlayers newPlayers lobby

            writeTVar gameLobby newLobby

            writeTChan (channel lobby) $ PlayerJoined newPlayer
            maybeServerGame <- handleLobbyFull app newLobby gameId

            return (newPlayer, maybeServerGame)

    handleLobbyFull :: App -> GameLobby -> T.Text -> STM (Maybe ServerGame)
    handleLobbyFull app lobby gameId =
        if (length (lobbyPlayers lobby) == (awaiting lobby)) then
            do
                -- Broadcast that the game is ready to begin
                let broadcastChannel = channel lobby
                writeTChan broadcastChannel (LobbyFull gameId)

                removeGameLobby app gameId
                serverGame <- (createGame app gameId lobby)
                return $ Just serverGame
        else
            return Nothing

    removeGameLobby :: App -> T.Text -> STM ()
    removeGameLobby app gameId =
        let lobbies = gameLobbies app
        in modifyTVar lobbies $ M.delete gameId

    createGame :: App -> T.Text -> GameLobby -> STM ServerGame
    createGame app gameId lobby =
        do
            let gamesInProgress = games app
            newChannel <- newBroadcastTChan
            newGame <- newTVar (pendingGame lobby)
            numConnections <- newTVar 0
            let serverGame = ServerGame newGame players newChannel numConnections
            return serverGame
        where
            players = lobbyPlayers lobby
