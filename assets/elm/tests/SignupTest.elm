module SignupTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, list, int, string)
import List
import Regex
import Signup
import Test exposing (..)


suite : Test
suite =
    describe "Signup.slugify"
        [ test "converts non-alphanumeric chars to dashes" <|
            \_ ->
                Expect.equal "foo-bar-baz" (Signup.slugify "Foo,Bar.Baz")
        , test "trims trailing and leading dashes" <|
            \_ ->
                Expect.equal "drip-inc" (Signup.slugify "Drip, Inc.")
        , fuzz string "truncates at 20 characters" <|
            Signup.slugify
                >> String.length
                >> Expect.atMost 20
        , fuzz string "generates valid URLs" <|
            Signup.slugify
                >> isValidUrl
                >> Expect.true "Not a valid URL"
        ]


isLower : String -> Bool
isLower str =
    String.toLower str == str


isAlphanumeric : String -> Bool
isAlphanumeric str =
    str
        |> Regex.contains (Regex.regex "[^a-z0-9-]")
        |> not


isValidUrl : String -> Bool
isValidUrl str =
    List.all
        ((|>) str)
        [ isLower, isAlphanumeric ]
