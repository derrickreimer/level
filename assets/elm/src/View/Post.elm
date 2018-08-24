module View.Post exposing (bodyView)

import Html exposing (..)
import Html.Attributes exposing (..)
import Post exposing (Post)


bodyView : Post.Record -> Html msg
bodyView postData =
    text ""
