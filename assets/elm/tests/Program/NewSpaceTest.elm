module Program.NewSpaceTest exposing (isAlphanumeric, isLower, isValidUrl, utils)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Json.Decode as Decode exposing (decodeString)
import List
import Program.NewSpace as NewSpace
import Regex
import Test exposing (..)


{-| Tests for utility functions.
-}
utils : Test
utils =
    describe "NewSpace.slugify"
        [ test "converts non-alphanumeric chars to dashes" <|
            \_ ->
                Expect.equal "foo-bar-baz" (NewSpace.slugify "Foo,Bar.Baz")
        , test "trims trailing and leading dashes" <|
            \_ ->
                Expect.equal "drip-inc" (NewSpace.slugify "Drip, Inc.")
        , fuzz string "truncates at 20 characters" <|
            NewSpace.slugify
                >> String.length
                >> Expect.atMost 20
        , fuzz string "generates valid URLs" <|
            NewSpace.slugify
                >> isValidUrl
                >> Expect.true "Not a valid URL"
        ]


{-| Determines if a given string is lowercase.

    isLower "yep" == True

    isLower "Nope" == False

-}
isLower : String -> Bool
isLower str =
    String.toLower str == str


{-| Determines if a given string is alphanumeric/dashes.

    isAlphanumeric "foo-bar-123" == True

    isAlphanumeric "withemphasis!" == False

-}
isAlphanumeric : String -> Bool
isAlphanumeric str =
    let
        regex =
            Maybe.withDefault Regex.never <|
                Regex.fromString "[^a-z0-9-]"
    in
    str
        |> Regex.contains regex
        |> not


{-| Determines if a given slug is valid for URLs.

    isValidUrl "FOO" == False

    isValidUrl "yay~~" == False

    isValidUrl "level" == True

-}
isValidUrl : String -> Bool
isValidUrl str =
    List.all
        ((|>) str)
        [ isLower, isAlphanumeric ]
