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
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Data.Post as Post exposing (Post)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import GraphQL exposing (Fragment)
import Util exposing (dateDecoder)


-- TYPES


type Mention
    = Mention Record


type alias Record =
    { id : String
    , post : Post
    , mentioners : List SpaceUser
    , lastOccurredAt : Date
    }


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment MentionFields on Mention {
          id
          post {
            ...PostFields
          }
          mentioners {
            ...SpaceUserFields
          }
          lastOccurredAt
        }
        """
        [ Post.fragment
        , SpaceUser.fragment
        ]



-- DECODERS


decoder : Decoder Mention
decoder =
    Decode.map Mention <|
        (Pipeline.decode Record
            |> Pipeline.required "id" Decode.string
            |> Pipeline.required "post" Post.decoder
            |> Pipeline.required "mentioners" (Decode.list SpaceUser.decoder)
            |> Pipeline.required "lastOccurredAt" dateDecoder
        )



-- API


getId : Mention -> String
getId (Mention { id }) =
    id


getCachedData : Mention -> Record
getCachedData (Mention data) =
    data
