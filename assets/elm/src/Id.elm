module Id exposing (Id, decoder, encoder)

import Json.Decode as Decode
import Json.Encode as Encode


type alias Id =
    String


decoder : Decode.Decoder Id
decoder =
    Decode.string


encoder : Id -> Encode.Value
encoder id =
    Encode.string id
