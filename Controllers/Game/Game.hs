module Controllers.Game.Game(
    handleChannelMessage,
    performRequest
) where

    import Prelude
    import Controllers.Game.Api

    handleChannelMessage :: GameMessage -> ServerResponse
    handleChannelMessage bleh = undefined

    performRequest :: ClientMessage -> IO ServerResponse
    performRequest clientMessage = undefined
