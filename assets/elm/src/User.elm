module User exposing (User, avatar, avatarUrl, decoder, displayName, email, firstName, fragment, handle, id, lastName, timeZone)

import Avatar
import GraphQL exposing (Fragment)
import Html exposing (Html)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, fail, field, int, maybe, string, succeed)



-- TYPES


type User
    = User Data


type alias Data =
    { id : Id
    , email : String
    , firstName : String
    , lastName : String
    , handle : String
    , avatarUrl : Maybe String
    , timeZone : String
    , fetchedAt : Int
    }


fragment : Fragment
fragment =
    GraphQL.toFragment
        """
        fragment UserFields on User {
          id
          email
          firstName
          lastName
          handle
          avatarUrl
          timeZone
          fetchedAt
        }
        """
        []



-- ACCESSORS


id : User -> Id
id (User data) =
    data.id


email : User -> String
email (User data) =
    data.email


firstName : User -> String
firstName (User data) =
    data.firstName


lastName : User -> String
lastName (User data) =
    data.lastName


handle : User -> String
handle (User data) =
    data.handle


timeZone : User -> String
timeZone (User data) =
    data.timeZone


avatarUrl : User -> Maybe String
avatarUrl (User data) =
    data.avatarUrl


displayName : User -> String
displayName (User data) =
    data.firstName ++ " " ++ data.lastName


avatar : Avatar.Size -> User -> Html msg
avatar size (User data) =
    Avatar.personAvatar size data



-- DECODERS


decoder : Decoder User
decoder =
    Decode.map User <|
        Decode.map8 Data
            (field "id" Id.decoder)
            (field "email" string)
            (field "firstName" string)
            (field "lastName" string)
            (field "handle" string)
            (field "avatarUrl" (maybe string))
            (field "timeZone" string)
            (field "fetchedAt" int)
