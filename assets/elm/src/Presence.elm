module Presence exposing (Event(..), Presence, PresenceList, Topic, decode, getUserId, getUserIds, isTyping, join, leave, receive, setTyping)

import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list, string)
import Json.Encode as Encode
import Ports


type Presence
    = Presence AggregateData


type alias AggregateData =
    { userId : Id
    , typing : Bool
    }


type alias IncomingData =
    { userId : Id
    , metas : List Meta
    }


type alias Meta =
    { typing : Bool }


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
    Ports.presenceOut <|
        Encode.object
            [ ( "method", Encode.string "join" )
            , ( "topic", Encode.string topic )
            ]


leave : String -> Cmd msg
leave topic =
    Ports.presenceOut <|
        Encode.object
            [ ( "method", Encode.string "leave" )
            , ( "topic", Encode.string topic )
            ]


setTyping : String -> Bool -> Cmd msg
setTyping topic val =
    Ports.presenceOut <|
        Encode.object
            [ ( "method", Encode.string "update" )
            , ( "topic", Encode.string topic )
            , ( "data", Encode.object [ ( "typing", Encode.bool val ) ] )
            ]



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


incomingDataDecoder : Decoder IncomingData
incomingDataDecoder =
    Decode.map2 IncomingData
        (field "userId" Id.decoder)
        (Decode.at [ "presence", "metas" ] (list metaDecoder))


metaDecoder : Decoder Meta
metaDecoder =
    Decode.map Meta
        (field "typing" Decode.bool)


aggregateIncomingData : IncomingData -> AggregateData
aggregateIncomingData incoming =
    AggregateData
        incoming.userId
        (List.any (\meta -> meta.typing) incoming.metas)


aggregateDataDecoder : Decoder AggregateData
aggregateDataDecoder =
    Decode.map aggregateIncomingData incomingDataDecoder


presenceDecoder : Decoder Presence
presenceDecoder =
    Decode.map Presence aggregateDataDecoder



-- API


getUserId : Presence -> String
getUserId (Presence { userId }) =
    userId


getUserIds : PresenceList -> List String
getUserIds list =
    List.map getUserId list


isTyping : Presence -> Bool
isTyping (Presence { typing }) =
    typing
