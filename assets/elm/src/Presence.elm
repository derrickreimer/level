module Presence exposing (Presence, State, decodeState, join, leave, receive, stateDecoder)

import Json.Decode as Decode exposing (Decoder, field, list, string)
import Ports


type alias Presence =
    { userId : String
    }


type alias State =
    { topic : String
    , list : List Presence
    }



-- INBOUND


receive : (Decode.Value -> msg) -> Sub msg
receive toMsg =
    Ports.presenceIn toMsg



-- OUTBOUND


join : String -> Cmd msg
join topic =
    Ports.presenceOut { method = "join", topic = topic }


leave : String -> Cmd msg
leave topic =
    Ports.presenceOut { method = "leave", topic = topic }



-- DECODERS


presenceDecoder : Decoder Presence
presenceDecoder =
    Decode.map Presence
        (field "userId" string)


stateDecoder : Decoder State
stateDecoder =
    Decode.map2 State
        (field "topic" string)
        (field "list" (list presenceDecoder))


decodeState : Decode.Value -> Result Decode.Error State
decodeState value =
    Decode.decodeValue stateDecoder value
