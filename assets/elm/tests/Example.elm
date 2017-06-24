module Example exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, list, int, string)
import Signup
import Test exposing (..)


suite : Test
suite =
    describe "Signup.slugify"
        [ test "converts spaces to dashes" <|
            \_ ->
                Expect.equal "abc-123" (Signup.slugify "abc 123")
        , test "downcases" <|
            \_ ->
                Expect.equal "foo" (Signup.slugify "Foo")
        ]
