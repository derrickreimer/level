module Scroll exposing (Container(..), toAnchor, toBottom)

import Scroll.Types exposing (AnchorParams, ContainerParams)
import Ports


-- TYPES


type alias Id =
    String


type Container
    = Document
    | ById String



-- API


toAnchor : Container -> Id -> Int -> Cmd msg
toAnchor container anchorId offset =
    Ports.scrollTo <| AnchorParams (containerId container) anchorId offset


toBottom : Container -> Cmd msg
toBottom container =
    Ports.scrollToBottom <| ContainerParams (containerId container)



-- INTERNAL


containerId : Container -> String
containerId container =
    case container of
        Document ->
            "DOCUMENT"

        ById id ->
            id
