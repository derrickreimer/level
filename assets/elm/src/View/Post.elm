module View.Post exposing (bodyView)

import Html exposing (..)
import Html.Attributes exposing (..)
import Data.Post as Post exposing (Post)


bodyView : Post.Record -> Html msg
bodyView postData =
    text ""
