module Data.Space
    exposing
        ( Space
        , Record
        , fragment
        , decoder
        , getId
        , getCachedData
        )

import Json.Decode as Decode exposing (Decoder, field, maybe, string)
import GraphQL exposing (Fragment)


-- TYPES


type Space
    = Space Record


type alias Record =
    { id : String
    , name : String
    , slug : String
    , avatarUrl : Maybe String
    }


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment SpaceFields on Space {
          id
          name
          slug
          avatarUrl
        }
        """
        []



-- DECODERS


decoder : Decoder Space
decoder =
    Decode.map Space <|
        Decode.map4 Record
            (field "id" string)
            (field "name" string)
            (field "slug" string)
            (field "avatarUrl" (maybe string))



-- API


getId : Space -> String
getId (Space { id }) =
    id


getCachedData : Space -> Record
getCachedData (Space record) =
    record
