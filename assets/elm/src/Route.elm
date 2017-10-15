module Route exposing (..)

{-| Routing logic for the application.
-}

import Data.Room as Room
import Navigation exposing (Location)
import UrlParser as Url exposing ((</>), Parser, oneOf, parsePath, s, string)


-- ROUTING --


type Route
    = Conversations
    | Room String -- TODO: Create a strong type for the room id param


route : Parser (Route -> a) a
route =
    oneOf
        [ Url.map Conversations (s "")
        , Url.map Room (s "rooms" </> Room.slugParser)
        ]



-- PUBLIC HELPERS


fromLocation : Location -> Maybe Route
fromLocation location =
    if String.isEmpty location.hash then
        Just Conversations
    else
        parsePath route location
