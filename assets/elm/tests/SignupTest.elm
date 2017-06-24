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
        [ test "converts spaces to dashes" <|
            \_ ->
                Expect.equal "abc-123" (Signup.slugify "abc 123")
        , fuzz string "generates valid URLs" <|
            Signup.slugify
                >> isValidUrl
                >> Expect.true "Not a valid URL"
        ]


isLower : String -> Bool
isLower str =
    String.toLower str == str


hasNoSpaces : String -> Bool
hasNoSpaces str =
    str
        |> Regex.contains (Regex.regex " ")
        |> not


isValidUrl : String -> Bool
isValidUrl str =
    List.all
        ((|>) str)
        [ isLower, hasNoSpaces ]
