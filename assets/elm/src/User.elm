module User exposing (User, avatar, avatarUrl, decoder, displayName, email, firstName, fragment, handle, hasChosenHandle, hasPassword, id, isDemo, lastName, timeZone)

import Avatar
import GraphQL exposing (Fragment)
import Html exposing (Html)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, fail, field, int, maybe, string, succeed)
import Json.Decode.Pipeline as Pipeline exposing (required)



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
    , isDemo : Bool
    , hasPassword : Bool
    , hasChosenHandle : Bool
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
          isDemo
          hasPassword
          hasChosenHandle
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


isDemo : User -> Bool
isDemo (User data) =
    data.isDemo


hasPassword : User -> Bool
hasPassword (User data) =
    data.hasPassword


hasChosenHandle : User -> Bool
hasChosenHandle (User data) =
    data.hasChosenHandle



-- DECODERS


decoder : Decoder User
decoder =
    Decode.map User
        (Decode.succeed Data
            |> required "id" Id.decoder
            |> required "email" string
            |> required "firstName" string
            |> required "lastName" string
            |> required "handle" string
            |> required "avatarUrl" (maybe string)
            |> required "timeZone" string
            |> required "isDemo" bool
            |> required "hasPassword" bool
            |> required "hasChosenHandle" bool
            |> required "fetchedAt" int
        )
