module Minutes exposing (toString)


toString : Int -> String
toString minutes =
    if minutes == 0 then
        "12a"

    else if minutes < 60 then
        "12" ++ formatMinutes (modBy 60 minutes) ++ "a"

    else if minutes < 720 then
        toAmString minutes

    else if minutes == 720 then
        "12p"

    else if minutes < 780 then
        "12" ++ formatMinutes (modBy 60 minutes) ++ "p"

    else
        toPmString minutes



-- PRIVATE


toAmString : Int -> String
toAmString minutes =
    let
        hour =
            minutes // 60

        minute =
            modBy 60 minutes
    in
    String.fromInt hour ++ formatMinutes minute ++ "a"


toPmString : Int -> String
toPmString minutes =
    let
        hour =
            (minutes - 720) // 60

        minute =
            modBy 60 minutes
    in
    String.fromInt hour ++ formatMinutes minute ++ "p"


formatMinutes : Int -> String
formatMinutes minutes =
    if minutes == 0 then
        ""

    else if minutes < 10 then
        ":0" ++ String.fromInt minutes

    else
        ":" ++ String.fromInt minutes
