module Presence exposing (Event(..), Presence, PresenceList, Topic, decode, getUserId, join, leave, receive)

import Json.Decode as Decode exposing (Decoder, field, list, string)
import Ports


type alias PresenceData =
    { userId : String
    }


type Presence
    = Presence PresenceData


type alias Topic =
    String


type alias PresenceList =
    List Presence


type Event
    = Sync Topic PresenceList
    | Join Topic Presence
    | Leave Topic Presence
    | Unknown



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


decode : Decode.Value -> Event
decode value =
    Decode.decodeValue decoder value
        |> Result.withDefault Unknown


decoder : Decoder Event
decoder =
    field "callback" string
        |> Decode.andThen eventDecoder


eventDecoder : String -> Decoder Event
eventDecoder callback =
    case callback of
        "onSync" ->
            Decode.map2 Sync
                (field "topic" string)
                (field "data" (list presenceDecoder))

        "onJoin" ->
            Decode.map2 Join
                (field "topic" string)
                (field "data" presenceDecoder)

        "onLeave" ->
            Decode.map2 Leave
                (field "topic" string)
                (field "data" presenceDecoder)

        _ ->
            Decode.succeed Unknown


presenceDecoder : Decoder Presence
presenceDecoder =
    Decode.map Presence <|
        Decode.map PresenceData (field "userId" string)



-- API


getUserId : Presence -> String
getUserId (Presence { userId }) =
    userId
