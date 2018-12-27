module Scroll exposing (Container(..), toBottom, toDocumentTop)

import Browser.Dom as Dom
import Ports
import Scroll.Types exposing (AnchorParams, ContainerParams)
import Task



-- TYPES


type alias Id =
    String


type Container
    = Document
    | ById String



-- This function (and the scrollTo port in JS) are commented out because they
-- are not currently being used. If the port remains uncommented, it errors out.
--
-- toAnchor : Container -> Id -> Int -> Cmd msg
-- toAnchor container anchorId offset =
--     Ports.scrollTo <| AnchorParams (containerId container) anchorId offset


toBottom : Container -> Cmd msg
toBottom container =
    Ports.scrollToBottom <| ContainerParams (containerId container)


toDocumentTop : msg -> Cmd msg
toDocumentTop msg =
    Task.perform (\_ -> msg) (Dom.setViewport 0 0)



-- INTERNAL


containerId : Container -> String
containerId container =
    case container of
        Document ->
            "DOCUMENT"

        ById id ->
            id
