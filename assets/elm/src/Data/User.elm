module Data.User exposing (User, fragment, decoder)

import Json.Decode as Decode exposing (Decoder, field, maybe, string, succeed, fail)
import GraphQL exposing (Fragment)


-- TYPES


type alias User =
    { id : String
    , email : String
    , firstName : String
    , lastName : String
    , avatarUrl : Maybe String
    }


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment UserFields on User {
          id
          email
          firstName
          lastName
          avatarUrl
        }
        """
        []



-- DECODERS


decoder : Decoder User
decoder =
    Decode.map5 User
        (field "id" string)
        (field "email" string)
        (field "firstName" string)
        (field "lastName" string)
        (field "avatarUrl" (maybe string))
