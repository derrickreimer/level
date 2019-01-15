module Beacon exposing (init, open, destroy)

import Json.Encode as Encode
import Ports



-- OUTBOUND


init : Cmd msg
init =
    Ports.beaconOut <|
        Encode.object
            [ ( "method", Encode.string "init" )
            ]


open : Cmd msg
open =
    Ports.beaconOut <|
        Encode.object
            [ ( "method", Encode.string "open" )
            ]

destroy : Cmd msg
destroy =
    Ports.beaconOut <|
        Encode.object
            [ ( "method", Encode.string "destroy" )
            ]
