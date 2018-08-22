module View.Post exposing (bodyView)

import Data.Post as Post exposing (Post)
import Html exposing (..)
import Html.Attributes exposing (..)


bodyView : Post.Record -> Html msg
bodyView postData =
    text ""
