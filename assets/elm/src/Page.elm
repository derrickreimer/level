module Page exposing (setTitle)

import Ports


setTitle : String -> Cmd msg
setTitle title =
    Ports.setTitle title
