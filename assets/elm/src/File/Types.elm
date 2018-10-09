module File.Types exposing (Data)

-- TYPES


type alias Data =
    { clientId : String
    , name : String
    , type_ : String
    , size : Int
    , contents : Maybe String
    }
