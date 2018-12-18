module Minutes exposing (toLongString, toString)


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


toLongString : Int -> String
toLongString minutes =
    if minutes == 0 then
        "12:00 am"

    else if minutes < 60 then
        "12" ++ formatLongMinutes (modBy 60 minutes) ++ " am"

    else if minutes < 720 then
        toLongAmString minutes

    else if minutes == 720 then
        "12:00 pm"

    else if minutes < 780 then
        "12" ++ formatLongMinutes (modBy 60 minutes) ++ " pm"

    else
        toLongPmString minutes



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


toLongAmString : Int -> String
toLongAmString minutes =
    let
        hour =
            minutes // 60

        minute =
            modBy 60 minutes
    in
    String.fromInt hour ++ formatLongMinutes minute ++ " am"


toLongPmString : Int -> String
toLongPmString minutes =
    let
        hour =
            (minutes - 720) // 60

        minute =
            modBy 60 minutes
    in
    String.fromInt hour ++ formatLongMinutes minute ++ " pm"


formatLongMinutes : Int -> String
formatLongMinutes minutes =
    if minutes == 0 then
        ":00"

    else if minutes < 10 then
        ":0" ++ String.fromInt minutes

    else
        ":" ++ String.fromInt minutes
