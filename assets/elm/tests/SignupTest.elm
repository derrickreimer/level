module SignupTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, list, int, string)
import List
import Regex
import Signup
import Test exposing (..)
import Json.Decode as Decode


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


decoders : Test
decoders =
    describe "decoders"
        [ describe "Signup.successDecoder"
            [ test "extracts the slug from JSON payload" <|
                \_ ->
                    let
                        payload =
                            """
                            {
                              "team": {
                                "id": 999,
                                "name": "Foo",
                                "slug": "foo",
                                "inserted_at": "2017-07-01T10:00:00Z",
                                "updated_at": "2017-07-01T10:00:00Z"
                              },
                              "user": {
                                "id": 888,
                                "email": "derrick@level.live",
                                "username": "derrick",
                                "inserted_at": "2017-07-01T10:00:00Z",
                                "updated_at": "2017-07-01T10:00:00Z"
                              },
                              "redirect_url": "http://example.com"
                            }
                            """

                        result =
                            payload
                                |> Decode.decodeString Signup.successDecoder
                    in
                        Expect.equal (Ok "http://example.com") result
            ]
        , describe "Signup.errorDecoder"
            [ test "extracts a list of validation errors" <|
                \_ ->
                    let
                        payload =
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
                            payload
                                |> Decode.decodeString Signup.errorDecoder

                        expected =
                            [ { attribute = "email"
                              , message = "is required"
                              }
                            ]
                    in
                        Expect.equal (Ok expected) result
            ]
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
