module Data.Room
    exposing
        ( RoomSubscriptionConnection
        , RoomSubscriptionEdge
        , RoomSubscription
        , Room
        , RoomMessageConnection
        , RoomMessageEdge
        , RoomMessage
        , SubscriberPolicy(..)
        , roomSubscriptionConnectionDecoder
        , roomSubscriptionDecoder
        , roomDecoder
        , roomMessageConnectionDecoder
        , roomMessageDecoder
        , slugParser
        , subscriberPolicyEncoder
        )

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Time exposing (Time)
import Data.User exposing (User, userDecoder)
import Data.PageInfo exposing (PageInfo, pageInfoDecoder)
import UrlParser
import Date exposing (Date)
import Util exposing (dateDecoder)


-- TYPES


type SubscriberPolicy
    = Public
    | InviteOnly
    | Mandatory


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
    , pageInfo : PageInfo
    }


type alias RoomMessageEdge =
    { node : RoomMessage
    }


type alias RoomMessage =
    { id : String
    , body : String
    , user : User
    , insertedAt : Date
    , insertedAtTs : Time
    }


type alias Room =
    { id : String
    , name : String
    , description : String
    , subscriberPolicy : SubscriberPolicy
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
        |> Pipeline.required "subscriberPolicy" subscriberPolicyDecoder


roomMessageConnectionDecoder : Decode.Decoder RoomMessageConnection
roomMessageConnectionDecoder =
    Pipeline.decode RoomMessageConnection
        |> Pipeline.custom (Decode.at [ "edges" ] (Decode.list roomMessageEdgeDecoder))
        |> Pipeline.custom (Decode.at [ "pageInfo" ] pageInfoDecoder)


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
        |> Pipeline.required "insertedAt" dateDecoder
        |> Pipeline.required "insertedAtTs" Decode.float


subscriberPolicyDecoder : Decode.Decoder SubscriberPolicy
subscriberPolicyDecoder =
    let
        convert : String -> Decode.Decoder SubscriberPolicy
        convert raw =
            case raw of
                "PUBLIC" ->
                    Decode.succeed Public

                "INVITE_ONLY" ->
                    Decode.succeed InviteOnly

                "MANDATORY" ->
                    Decode.succeed Mandatory

                _ ->
                    Decode.fail "Subscriber policy not valid"
    in
        Decode.string |> Decode.andThen convert



-- ENCODERS


subscriberPolicyEncoder : SubscriberPolicy -> Encode.Value
subscriberPolicyEncoder raw =
    case raw of
        Public ->
            Encode.string "PUBLIC"

        InviteOnly ->
            Encode.string "INVITE_ONLY"

        Mandatory ->
            Encode.string "MANDATORY"



-- ROUTING


slugParser : UrlParser.Parser (String -> a) a
slugParser =
    UrlParser.string
