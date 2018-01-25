module Data.Invitation exposing (InvitationConnection, Invitation, invitationConnectionDecoder)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Date exposing (Date)
import Data.PageInfo exposing (PageInfo, pageInfoDecoder)
import Util exposing (dateDecoder)


-- TYPES


type alias InvitationConnection =
    { edges : List InvitationEdge
    , pageInfo : PageInfo
    , totalCount : Int
    }


type alias InvitationEdge =
    { node : Invitation
    }


type alias Invitation =
    { id : String
    , email : String
    , insertedAt : Date
    }



-- DECODERS


invitationConnectionDecoder : Decode.Decoder InvitationConnection
invitationConnectionDecoder =
    Pipeline.decode InvitationConnection
        |> Pipeline.custom (Decode.at [ "edges" ] (Decode.list invitationEdgeDecoder))
        |> Pipeline.custom (Decode.at [ "pageInfo" ] pageInfoDecoder)
        |> Pipeline.custom (Decode.at [ "totalCount" ] Decode.int)


invitationEdgeDecoder : Decode.Decoder InvitationEdge
invitationEdgeDecoder =
    Pipeline.decode InvitationEdge
        |> Pipeline.custom (Decode.at [ "node" ] invitationDecoder)


invitationDecoder : Decode.Decoder Invitation
invitationDecoder =
    Pipeline.decode Invitation
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "email" Decode.string
        |> Pipeline.required "insertedAt" dateDecoder
