module User exposing (Record, User, avatarUrl, decoder, email, firstName, fragment, getCachedData, handle, id, lastName)

import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, fail, field, int, maybe, string, succeed)



-- TYPES


type User
    = User Record


type alias Record =
    { id : String
    , email : String
    , firstName : String
    , lastName : String
    , handle : String
    , avatarUrl : Maybe String
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
          fetchedAt
        }
        """
        []



-- ACCESSORS


id : User -> String
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


avatarUrl : User -> Maybe String
avatarUrl (User data) =
    data.avatarUrl



-- DECODERS


decoder : Decoder User
decoder =
    Decode.map User <|
        Decode.map7 Record
            (field "id" string)
            (field "email" string)
            (field "firstName" string)
            (field "lastName" string)
            (field "handle" string)
            (field "avatarUrl" (maybe string))
            (field "fetchedAt" int)



-- API


getCachedData : User -> Record
getCachedData (User record) =
    record
