module Query.Bootstrap exposing (request, Team, Response)

import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import GraphQL


type alias Team =
    { id : String
    , name : String
    }


type alias Response =
    { id : String
    , firstName : String
    , lastName : String
    , team : Team
    }


query : String
query =
    """
      {
        viewer {
          id
          username
          firstName
          lastName
          team {
            id
            name
          }
        }
      }
    """


teamDecoder : Decode.Decoder Team
teamDecoder =
    Pipeline.decode Team
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "name" Decode.string


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "viewer" ] <|
        (Pipeline.decode Response
            |> Pipeline.required "id" Decode.string
            |> Pipeline.required "firstName" Decode.string
            |> Pipeline.required "lastName" Decode.string
            |> Pipeline.custom (Decode.at [ "team" ] teamDecoder)
        )


request : String -> Http.Request Response
request apiToken =
    GraphQL.request apiToken query Nothing decoder
