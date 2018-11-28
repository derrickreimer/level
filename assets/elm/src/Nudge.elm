module Nudge exposing (Nudge, decoder, fragment, id, minute)

import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)


type Nudge
    = Nudge Data


type alias Data =
    { id : Id
    , minute : Int
    }



-- ACCESSORS


id : Nudge -> Id
id (Nudge data) =
    data.id


minute : Nudge -> Int
minute (Nudge data) =
    data.minute



-- GRAPHQL


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment NudgeFields on Nudge {
              id
              minute
            }
            """
    in
    GraphQL.toFragment queryBody []



-- DECODERS


decoder : Decoder Nudge
decoder =
    Decode.map Nudge <|
        Decode.map2 Data
            (Decode.field "id" Id.decoder)
            (Decode.field "minute" Decode.int)
