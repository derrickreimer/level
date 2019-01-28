module SpaceBot exposing (SpaceBot, avatar, avatarUrl, decoder, displayName, fragment, handle, id, initials, spaceId)

import Avatar
import GraphQL exposing (Fragment)
import Html exposing (Html)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, fail, field, int, maybe, string, succeed)
import Json.Decode.Pipeline as Pipeline exposing (required)



-- TYPES


type SpaceBot
    = SpaceBot Data


type alias Data =
    { id : Id
    , spaceId : Id
    , displayName : String
    , handle : String
    , avatarUrl : Maybe String
    , fetchedAt : Int
    }


fragment : Fragment
fragment =
    GraphQL.toFragment
        """
        fragment SpaceBotFields on SpaceBot {
          id
          space {
            id
          }
          displayName
          handle
          avatarUrl
          fetchedAt
        }
        """
        []



-- ACCESSORS


id : SpaceBot -> Id
id (SpaceBot data) =
    data.id


spaceId : SpaceBot -> Id
spaceId (SpaceBot data) =
    data.spaceId


displayName : SpaceBot -> String
displayName (SpaceBot data) =
    data.displayName


initials : SpaceBot -> String
initials (SpaceBot data) =
    data.displayName
        |> String.left 1
        |> String.toUpper


avatarUrl : SpaceBot -> Maybe String
avatarUrl (SpaceBot data) =
    data.avatarUrl


handle : SpaceBot -> String
handle (SpaceBot data) =
    data.handle


avatar : Avatar.Size -> SpaceBot -> Html msg
avatar size (SpaceBot data) =
    Avatar.botAvatar size data



-- DECODERS


decoder : Decoder SpaceBot
decoder =
    Decode.map SpaceBot
        (Decode.succeed Data
            |> required "id" Id.decoder
            |> required "space" (field "id" Id.decoder)
            |> required "displayName" string
            |> required "handle" string
            |> required "avatarUrl" (maybe string)
            |> required "fetchedAt" int
        )
