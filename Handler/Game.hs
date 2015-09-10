module Handler.Game where

import Import
import Yesod.Core
import Yesod.WebSockets
import qualified Data.Text.Lazy as TL
import qualified Data.Monoid as M
import Data.Text (Text)
import Controllers.Game.Model.ServerGame
import Widgets.Game.Game
import Controllers.Game.Api
import qualified Data.List as L
import Controllers.Game.Model.ServerPlayer

getGameR :: Text -> Handler Html
getGameR gameId = do
    request <- getRequest
    app <- getYesod
    let cookies = reqCookies request
    let maybePlayerId = L.lookup "id" cookies
    let gamesInProgress = games app
    maybeGame <- atomically $ lookup gameId <$> readTVar gamesInProgress

    case maybeGame of
        Nothing -> notFound
        Just game ->
            do
                (currentGame, messageChannel) <- atomically $ setupPrerequisets game
                let maybePlayerNumber = maybePlayerId >>= getPlayerNumber currentGame
                webSockets $ gameApp game messageChannel maybePlayerId maybePlayerNumber
                defaultLayout $ do
                    [whamlet|
                        ^{gameInPlay currentGame maybePlayerNumber}
                    |]
                    toWidget
                        [julius|
                            var url = document.URL,

                            url = url.replace("http:", "ws:").replace("https:", "wss:");
                            var conn = new WebSocket(url);

                            conn.onmessage = function(e) {
                                console.dir(e);
                            }
                        |]

getPlayerNumber :: ServerGame -> Text -> Maybe Int
getPlayerNumber serverGame playerId = fst <$> (L.find (\(ind, player) -> playerId == identifier player) $ zip [1 .. 4] players)
    where
        players = playing serverGame

setupPrerequisets :: TVar ServerGame -> STM (ServerGame, TChan GameMessage)
setupPrerequisets serverGame =
    do
        game <- readTVar serverGame
        channel <- cloneTChan $ broadcastChannel game
        return (game, channel)


gameApp :: TVar ServerGame -> TChan GameMessage -> Maybe Text -> Maybe Int -> WebSocketsT Handler ()
gameApp game channel maybePlayerId playerNumber =
    do
        sendPing ("testarooni" :: Text)


{-testApp :: WebSocketsT Handler ()
testApp = do
    sendTextData ("blah blah message 1" :: Text)
    sendTextData $ (("blah blah message 2") :: Text)
    redirect HomeR
-}