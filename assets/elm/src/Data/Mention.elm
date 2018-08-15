module Data.Mention
    exposing
        ( Mention
        , Record
        , fragment
        , decoder
        , getId
        , getCachedData
        )

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder, field)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import GraphQL exposing (Fragment)
import Util exposing (dateDecoder)


-- TYPES


type Mention
    = Mention Record


type alias Record =
    { id : String
    , mentioners : List SpaceUser
    , lastOccurredAt : Date
    }


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment MentionFields on Mention {
          id
          mentioners {
            ...SpaceUserFields
          }
          lastOccurredAt
        }
        """
        [ SpaceUser.fragment
        ]



-- DECODERS


decoder : Decoder Mention
decoder =
    Decode.map Mention <|
        (Decode.map3 Record
            (field "id" Decode.string)
            (field "mentioners" (Decode.list SpaceUser.decoder))
            (field "lastOccurredAt" dateDecoder)
        )



-- API


getId : Mention -> String
getId (Mention { id }) =
    id


getCachedData : Mention -> Record
getCachedData (Mention data) =
    data
