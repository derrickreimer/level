module Vendor.Base64.Decode exposing (decode)

import Bitwise exposing (and, or, shiftLeftBy, shiftRightZfBy)
import Char
import Regex exposing (Regex, regex)


decode : String -> Result String String
decode =
    pad >> validateAndDecode


validateAndDecode : String -> Result String String
validateAndDecode input =
    input
        |> validate
        |> Result.andThen (String.foldl chomp initial >> wrapUp)
        |> Result.map (stripNulls input)


pad : String -> String
pad input =
    case rem (String.length input) 4 of
        3 ->
            input ++ "="

        2 ->
            input ++ "=="

        _ ->
            input


validate : String -> Result String String
validate input =
    if Regex.contains validBase64Regex input then
        Ok input

    else
        Err "Invalid base64"


validBase64Regex : Regex
validBase64Regex =
    regex "^([A-Za-z0-9\\/+]{4})*([A-Za-z0-9\\/+]{2}[A-Za-z0-9\\/+=]{2})?$"


stripNulls : String -> String -> String
stripNulls input output =
    if String.endsWith "==" input then
        String.dropRight 2 output

    else if String.endsWith "=" input then
        String.dropRight 1 output

    else
        output


wrapUp : Accumulator -> Result String String
wrapUp ( _, _, ( _, need, res ) ) =
    if need > 0 then
        Err "Invalid UTF-16"

    else
        Ok res


type alias Accumulator =
    ( Int, Int, Utf8ToUtf16 )


type alias Base64ToUtf8 =
    ( Int, Int )


type alias Utf8ToUtf16 =
    ( Int, Int, String )


initial : Accumulator
initial =
    ( 0, 0, ( 0, 0, "" ) )


chomp : Char -> Accumulator -> Accumulator
chomp char_ ( curr, cnt, utf8ToUtf16 ) =
    let
        char : Int
        char =
            charToInt char_
    in
    case cnt of
        3 ->
            toUTF16 (or curr char) utf8ToUtf16

        _ ->
            ( or (shiftLeftBy ((3 - cnt) * 6) char) curr, cnt + 1, utf8ToUtf16 )


toUTF16 : Int -> Utf8ToUtf16 -> Accumulator
toUTF16 char acc =
    ( 0
    , 0
    , acc
        |> add (shiftRightZfBy 16 char |> and 0xFF)
        |> add (shiftRightZfBy 8 char |> and 0xFF)
        |> add (shiftRightZfBy 0 char |> and 0xFF)
    )


add : Int -> Utf8ToUtf16 -> Utf8ToUtf16
add char ( curr, need, res ) =
    let
        shiftAndAdd : Int -> Int
        shiftAndAdd int =
            shiftLeftBy 6 curr
                |> or (and 0x3F int)
    in
    if need == 0 then
        if and 0x80 char == 0 then
            ( 0, 0, res ++ intToString char )

        else if and 0xE0 char == 0xC0 then
            ( and 0x1F char, 1, res )

        else if and 0xF0 char == 0xE0 then
            ( and 0x0F char, 2, res )

        else
            ( and 7 char, 3, res )

    else if need == 1 then
        ( 0, 0, res ++ intToString (shiftAndAdd char) )

    else
        ( shiftAndAdd char, need - 1, res )


intToString : Int -> String
intToString int =
    if int <= 0x00010000 then
        Char.fromCode int |> String.fromChar

    else
        let
            c =
                int - 0x00010000
        in
        [ Char.fromCode (shiftRightZfBy 10 c |> or 0xD800)
        , Char.fromCode (and 0x03FF c |> or 0xDC00)
        ]
            |> String.fromList


charToInt : Char -> Int
charToInt char =
    case char of
        'A' ->
            0

        'B' ->
            1

        'C' ->
            2

        'D' ->
            3

        'E' ->
            4

        'F' ->
            5

        'G' ->
            6

        'H' ->
            7

        'I' ->
            8

        'J' ->
            9

        'K' ->
            10

        'L' ->
            11

        'M' ->
            12

        'N' ->
            13

        'O' ->
            14

        'P' ->
            15

        'Q' ->
            16

        'R' ->
            17

        'S' ->
            18

        'T' ->
            19

        'U' ->
            20

        'V' ->
            21

        'W' ->
            22

        'X' ->
            23

        'Y' ->
            24

        'Z' ->
            25

        'a' ->
            26

        'b' ->
            27

        'c' ->
            28

        'd' ->
            29

        'e' ->
            30

        'f' ->
            31

        'g' ->
            32

        'h' ->
            33

        'i' ->
            34

        'j' ->
            35

        'k' ->
            36

        'l' ->
            37

        'm' ->
            38

        'n' ->
            39

        'o' ->
            40

        'p' ->
            41

        'q' ->
            42

        'r' ->
            43

        's' ->
            44

        't' ->
            45

        'u' ->
            46

        'v' ->
            47

        'w' ->
            48

        'x' ->
            49

        'y' ->
            50

        'z' ->
            51

        '0' ->
            52

        '1' ->
            53

        '2' ->
            54

        '3' ->
            55

        '4' ->
            56

        '5' ->
            57

        '6' ->
            58

        '7' ->
            59

        '8' ->
            60

        '9' ->
            61

        '+' ->
            62

        '/' ->
            63

        _ ->
            0
