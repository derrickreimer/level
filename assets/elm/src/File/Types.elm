module File.Types exposing (Data)

-- TYPES


type alias Data =
    { id : String
    , name : String
    , type_ : String
    , size : Int
    , contents : String
    }
