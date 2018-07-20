module Data.User exposing (User, fragment, decoder)

import Json.Decode as Decode exposing (Decoder, field, string, succeed, fail)
import GraphQL exposing (Fragment)


-- TYPES


type alias User =
    { id : String
    , email : String
    , firstName : String
    , lastName : String
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
        }
        """
        []



-- DECODERS


decoder : Decoder User
decoder =
    Decode.map4 User
        (field "id" string)
        (field "email" string)
        (field "firstName" string)
        (field "lastName" string)
