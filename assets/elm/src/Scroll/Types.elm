module Scroll.Types exposing (AnchorParams, ContainerParams)

-- TYPES


type alias AnchorParams =
    { containerId : String
    , anchorId : String
    , offset : Int
    }


type alias ContainerParams =
    { containerId : String
    }
