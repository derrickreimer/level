module SignupTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, list, int, string)
import List
import Regex
import Signup
import Test exposing (..)
import Json.Decode as Decode exposing (decodeString)


{-| Tests for utility functions.
-}
utils : Test
utils =
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


{-| Tests for JSON decoders.
-}
decoders : Test
decoders =
    describe "decoders"
        [ describe "Signup.successDecoder"
            [ test "extracts the slug from JSON payload" <|
                \_ ->
                    let
                        json =
                            """
                            {
                                "space": {
                                    "id": 999,
                                    "name": "Foo",
                                    "slug": "foo",
                                    "inserted_at": "2017-07-01T10:00:00Z",
                                    "updated_at": "2017-07-01T10:00:00Z"
                                },
                                "user": {
                                    "id": 888,
                                    "email": "derrick@level.live",
                                    "inserted_at": "2017-07-01T10:00:00Z",
                                    "updated_at": "2017-07-01T10:00:00Z"
                                },
                                "redirect_url": "http://example.com"
                            }
                            """

                        result =
                            decodeString Signup.successDecoder json
                    in
                        Expect.equal (Ok "http://example.com") result
            ]
        , describe "Signup.failureDecoder"
            [ test "extracts a list of validation errors" <|
                \_ ->
                    let
                        json =
                            """
                            {
                                "errors": [
                                    {
                                        "attribute": "email",
                                        "message": "is required",
                                        "properties": { "validation": "required" }
                                    }
                                ]
                            }
                            """

                        result =
                            decodeString Signup.failureDecoder json

                        expected =
                            [ { attribute = "email"
                              , message = "is required"
                              }
                            ]
                    in
                        Expect.equal (Ok expected) result
            ]
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
    str
        |> Regex.contains (Regex.regex "[^a-z0-9-]")
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
