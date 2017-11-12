module Data.Room
    exposing
        ( RoomSubscriptionConnection
        , RoomSubscriptionEdge
        , RoomSubscription
        , Room
        , RoomMessageConnection
        , RoomMessageEdge
        , RoomMessage
        , roomSubscriptionConnectionDecoder
        , roomDecoder
        , roomMessageConnectionDecoder
        , roomMessageDecoder
        , slugParser
        )

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Time exposing (Time)
import Data.User exposing (User, userDecoder)
import UrlParser


-- TYPES


type alias RoomSubscriptionConnection =
    { edges : List RoomSubscriptionEdge
    }


type alias RoomSubscriptionEdge =
    { node : RoomSubscription
    }


type alias RoomSubscription =
    { room : Room
    }


type alias RoomMessageConnection =
    { edges : List RoomMessageEdge
    }


type alias RoomMessageEdge =
    { node : RoomMessage
    }


type alias RoomMessage =
    { id : String
    , body : String
    , user : User
    , insertedAt : Time
    }


type alias Room =
    { id : String
    , name : String
    , description : String
    }



-- DECODERS


roomSubscriptionConnectionDecoder : Decode.Decoder RoomSubscriptionConnection
roomSubscriptionConnectionDecoder =
    Pipeline.decode RoomSubscriptionConnection
        |> Pipeline.custom (Decode.at [ "edges" ] (Decode.list roomSubscriptionEdgeDecoder))


roomSubscriptionEdgeDecoder : Decode.Decoder RoomSubscriptionEdge
roomSubscriptionEdgeDecoder =
    Pipeline.decode RoomSubscriptionEdge
        |> Pipeline.custom (Decode.at [ "node" ] roomSubscriptionDecoder)


roomSubscriptionDecoder : Decode.Decoder RoomSubscription
roomSubscriptionDecoder =
    Pipeline.decode RoomSubscription
        |> Pipeline.custom (Decode.at [ "room" ] roomDecoder)


roomDecoder : Decode.Decoder Room
roomDecoder =
    Pipeline.decode Room
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "description" Decode.string


roomMessageConnectionDecoder : Decode.Decoder RoomMessageConnection
roomMessageConnectionDecoder =
    Pipeline.decode RoomMessageConnection
        |> Pipeline.custom (Decode.at [ "edges" ] (Decode.list roomMessageEdgeDecoder))


roomMessageEdgeDecoder : Decode.Decoder RoomMessageEdge
roomMessageEdgeDecoder =
    Pipeline.decode RoomMessageEdge
        |> Pipeline.custom (Decode.at [ "node" ] roomMessageDecoder)


roomMessageDecoder : Decode.Decoder RoomMessage
roomMessageDecoder =
    Pipeline.decode RoomMessage
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "body" Decode.string
        |> Pipeline.custom (Decode.at [ "user" ] userDecoder)
        |> Pipeline.required "insertedAtTs" Decode.float



-- ROUTING


slugParser : UrlParser.Parser (String -> a) a
slugParser =
    UrlParser.string
