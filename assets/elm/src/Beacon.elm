module Beacon exposing (open)

import Json.Encode as Encode
import Ports



-- OUTBOUND


open : Cmd msg
open =
    Ports.beaconOut <|
        Encode.object
            [ ( "method", Encode.string "open" )
            ]
