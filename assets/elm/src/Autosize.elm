module Autosize exposing (destroy, init, update)

import Autosize.Types exposing (Args)
import Ports



-- API


init : String -> Cmd msg
init id =
    Ports.autosize (Args "init" id)


update : String -> Cmd msg
update id =
    Ports.autosize (Args "update" id)


destroy : String -> Cmd msg
destroy id =
    Ports.autosize (Args "destroy" id)
