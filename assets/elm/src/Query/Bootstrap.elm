module Query.Bootstrap exposing (request, Space, Response)

import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import GraphQL


type alias Space =
    { id : String
    , name : String
    }


type alias Response =
    { id : String
    , firstName : String
    , lastName : String
    , space : Space
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
          space {
            id
            name
          }
        }
      }
    """


spaceDecoder : Decode.Decoder Space
spaceDecoder =
    Pipeline.decode Space
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "name" Decode.string


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "viewer" ] <|
        (Pipeline.decode Response
            |> Pipeline.required "id" Decode.string
            |> Pipeline.required "firstName" Decode.string
            |> Pipeline.required "lastName" Decode.string
            |> Pipeline.custom (Decode.at [ "space" ] spaceDecoder)
        )


request : String -> Http.Request Response
request apiToken =
    GraphQL.request apiToken query Nothing decoder
