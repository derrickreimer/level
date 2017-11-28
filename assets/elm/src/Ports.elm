port module Ports exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode


-- INBOUND


port startFrames : (Decode.Value -> msg) -> Sub msg


port resultFrames : (Decode.Value -> msg) -> Sub msg



-- OUTBOUND


type alias Frame =
    { operation : String
    , variables : Maybe Encode.Value
    }


port sendFrame : Frame -> Cmd msg
