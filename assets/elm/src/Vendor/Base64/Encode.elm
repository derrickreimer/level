module Vendor.Base64.Encode exposing (encode)

import Bitwise exposing (and, or, shiftLeftBy, shiftRightZfBy)
import Char


encode : String -> String
encode input =
    String.foldl chomp initial input |> wrapUp


type alias Accumulator =
    ( UTF8Accumulator, UTF8ToBase64Accumulator )


initial : Accumulator
initial =
    ( Nothing, ( "", 0, 0 ) )


wrapUp : Accumulator -> String
wrapUp ( _, ( res, cnt, acc ) ) =
    case cnt of
        1 ->
            res
                ++ (shiftRightZfBy 2 acc |> and 0x3F |> intToBase64)
                ++ (shiftLeftBy 4 acc |> and 0x3F |> intToBase64)
                ++ "=="

        2 ->
            res
                ++ (shiftRightZfBy 10 acc |> and 0x3F |> intToBase64)
                ++ (shiftRightZfBy 4 acc |> and 0x3F |> intToBase64)
                ++ (shiftLeftBy 2 acc |> and 0x3F |> intToBase64)
                ++ "="

        _ ->
            res


type alias UTF8Accumulator =
    Maybe Int


type alias UTF8ToBase64Accumulator =
    ( String, Int, Int )


chomp : Char -> Accumulator -> Accumulator
chomp char_ ( utf8Acc, base64Acc ) =
    let
        char : Int
        char =
            Char.toCode char_
    in
    case utf8Acc of
        Nothing ->
            if char < 0x80 then
                ( Nothing
                , base64Acc
                    |> add char
                )

            else if char < 0x0800 then
                ( Nothing
                , base64Acc
                    |> add (or 0xC0 (shiftRightZfBy 6 char))
                    |> add (or 0x80 (and 0x3F char))
                )

            else if char < 0xD800 || char >= 0xE000 then
                ( Nothing
                , base64Acc
                    |> add (or 0xE0 (shiftRightZfBy 12 char))
                    |> add (or 0x80 (and 0x3F (shiftRightZfBy 6 char)))
                    |> add (or 0x80 (and 0x3F char))
                )

            else
                ( Just char, base64Acc )

        Just prev ->
            let
                combined : Int
                combined =
                    prev
                        |> and 0x03FF
                        |> shiftLeftBy 10
                        |> or (and 0x03FF char)
                        |> (+) 0x00010000
            in
            ( Nothing
            , base64Acc
                |> add (or 0xF0 (shiftRightZfBy 18 combined))
                |> add (or 0x80 (and 0x3F (shiftRightZfBy 12 combined)))
                |> add (or 0x80 (and 0x3F (shiftRightZfBy 6 combined)))
                |> add (or 0x80 (and 0x3F combined))
            )


add : Int -> UTF8ToBase64Accumulator -> UTF8ToBase64Accumulator
add char ( res, count, acc ) =
    let
        current =
            or (shiftLeftBy 8 acc) char
    in
    case count of
        2 ->
            ( res ++ toBase64 current, 0, 0 )

        _ ->
            ( res, count + 1, current )


toBase64 : Int -> String
toBase64 int =
    (shiftRightZfBy 18 int |> and 0x3F |> intToBase64)
        ++ (shiftRightZfBy 12 int |> and 0x3F |> intToBase64)
        ++ (shiftRightZfBy 6 int |> and 0x3F |> intToBase64)
        ++ (shiftRightZfBy 0 int |> and 0x3F |> intToBase64)


intToBase64 : Int -> String
intToBase64 i =
    case i of
        0 ->
            "A"

        1 ->
            "B"

        2 ->
            "C"

        3 ->
            "D"

        4 ->
            "E"

        5 ->
            "F"

        6 ->
            "G"

        7 ->
            "H"

        8 ->
            "I"

        9 ->
            "J"

        10 ->
            "K"

        11 ->
            "L"

        12 ->
            "M"

        13 ->
            "N"

        14 ->
            "O"

        15 ->
            "P"

        16 ->
            "Q"

        17 ->
            "R"

        18 ->
            "S"

        19 ->
            "T"

        20 ->
            "U"

        21 ->
            "V"

        22 ->
            "W"

        23 ->
            "X"

        24 ->
            "Y"

        25 ->
            "Z"

        26 ->
            "a"

        27 ->
            "b"

        28 ->
            "c"

        29 ->
            "d"

        30 ->
            "e"

        31 ->
            "f"

        32 ->
            "g"

        33 ->
            "h"

        34 ->
            "i"

        35 ->
            "j"

        36 ->
            "k"

        37 ->
            "l"

        38 ->
            "m"

        39 ->
            "n"

        40 ->
            "o"

        41 ->
            "p"

        42 ->
            "q"

        43 ->
            "r"

        44 ->
            "s"

        45 ->
            "t"

        46 ->
            "u"

        47 ->
            "v"

        48 ->
            "w"

        49 ->
            "x"

        50 ->
            "y"

        51 ->
            "z"

        52 ->
            "0"

        53 ->
            "1"

        54 ->
            "2"

        55 ->
            "3"

        56 ->
            "4"

        57 ->
            "5"

        58 ->
            "6"

        59 ->
            "7"

        60 ->
            "8"

        61 ->
            "9"

        62 ->
            "+"

        _ ->
            "/"
