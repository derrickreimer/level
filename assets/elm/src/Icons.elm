module Icons exposing (Toggle(..), alert, arrowLeft, arrowRight, arrowUpRight, atSign, bookmark, check, checkSquare, chevronDown, chevronRight, chevronUp, closed, closedAvatar, closedSmall, comment, commentWhite, edit, ex, eye, file, filter, hash, heart, home, image, inbox, inboxWhite, lock, lockLarge, logOut, logo, logomark, menu, more, open, plus, postbot, refresh, reply, revokeMember, search, sendWhite, settings, shield, square, thumbs, thumbsMedium, thumbsSmall, undismissed, unlock, zapWhite)

import Color exposing (Color)
import Html exposing (Html)
import Html.Attributes
import Svg exposing (..)
import Svg.Attributes exposing (..)


type Toggle
    = On
    | Off


iconView : Html msg -> Html msg
iconView svg =
    Html.div [ Html.Attributes.class "flex items-center" ] [ svg ]


alert : Toggle -> Html msg
alert toggle =
    case toggle of
        Off ->
            iconView <|
                svg [ width "20px", height "20px", viewBox "0 0 20 20", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd" ] [ g [ id "alert-circle", transform "translate(1.000000, 1.000000)" ] [ circle [ id "Oval", stroke "#8A98A5", strokeLinecap "round", strokeLinejoin "round", cx "9", cy "9", r "9" ] [], Svg.path [ d "M9,5.4 L9,9", id "Path", stroke "#8A98A5", strokeWidth "2", strokeLinecap "round", strokeLinejoin "round" ] [], circle [ id "Oval", fill "#8A98A5", fillRule "nonzero", cx "9", cy "12.6", r "1" ] [] ] ] ]

        On ->
            iconView <|
                svg [ width "20px", height "20px", viewBox "0 0 20 20", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd" ] [ g [ id "alert-circle-copy", transform "translate(1.000000, 1.000000)" ] [ circle [ id "Oval", stroke "#FF1E12", fill "#FF1E12", strokeLinecap "round", strokeLinejoin "round", cx "9", cy "9", r "9" ] [], Svg.path [ d "M9,5.4 L9,9", id "Path", stroke "#FFFFFF", strokeWidth "2", strokeLinecap "round", strokeLinejoin "round" ] [], circle [ id "Oval", fill "#FFFFFF", fillRule "nonzero", cx "9", cy "12.6", r "1" ] [] ] ] ]


arrowLeft : Toggle -> Html msg
arrowLeft toggle =
    iconView <|
        svg [ width "16px", height "14px", viewBox "0 0 16 14", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "arrow-left", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M14,6 L0,6", id "Shape" ] [], polyline [ id "Shape", points "6 12 0 6 6 0" ] [] ] ] ]


arrowRight : Toggle -> Html msg
arrowRight toggle =
    iconView <|
        svg [ width "16px", height "14px", viewBox "0 0 16 14", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "arrow-right", transform "translate(8.000000, 7.000000) scale(-1, 1) translate(-8.000000, -7.000000) translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M14,6 L0,6", id "Shape" ] [], polyline [ id "Shape", points "6 12 0 6 6 0" ] [] ] ] ]


arrowUpRight : Html msg
arrowUpRight =
    iconView <|
        svg [ width "10px", height "10px", viewBox "0 0 10 10", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "arrow-up-right", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M0,8 L8,0", id "Shape" ] [], polyline [ id "Shape", points "0 0 8 0 8 8" ] [] ] ] ]


atSign : Html msg
atSign =
    iconView <|
        svg [ width "19px", height "19px", viewBox "0 0 19 19", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "at-sign-copy", transform "translate(0.000000, 1.000000)", stroke "#8A98A5" ] [ circle [ id "Oval", cx "9.42857143", cy "8.57142857", r "3.42857143" ] [], Svg.path [ d "M12.8571429,5.14285714 L12.8571429,9.42857143 C12.8571429,10.8487322 14.0084106,12 15.4285714,12 C16.8487322,12 18,10.8487322 18,9.42857143 L18,8.57142857 C17.9997492,4.58820392 15.2555438,1.13006942 11.3765473,0.224826446 C7.4975508,-0.680416523 3.50612707,1.20582152 1.74279079,4.77747714 C-0.0205454833,8.34913276 0.908957691,12.664846 3.98625274,15.1939435 C7.06354778,17.7230409 11.4775705,17.7989434 14.64,15.3771429", id "Shape" ] [] ] ] ]


bookmark : Toggle -> Html msg
bookmark toggle =
    case toggle of
        Off ->
            iconView <|
                svg [ width "16px", height "20px", viewBox "0 0 16 20", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "bookmark", transform "translate(1.000000, 1.000000)", fill "#E2E6E8", stroke "#E2E6E8", strokeWidth "2" ] [ Svg.path [ d "M14,18 L7,13 L0,18 L0,2 C0,0.8954305 0.8954305,0 2,0 L12,0 C13.1045695,0 14,0.8954305 14,2 L14,18 Z", id "Shape" ] [] ] ] ]

        On ->
            iconView <|
                svg [ width "16px", height "20px", viewBox "0 0 16 20", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "bookmark-copy", transform "translate(1.000000, 1.000000)", fill "#13C1D5", stroke "#13C1D5", strokeWidth "2" ] [ Svg.path [ d "M14,18 L7,13 L0,18 L0,2 C0,0.8954305 0.8954305,0 2,0 L12,0 C13.1045695,0 14,0.8954305 14,2 L14,18 Z", id "Shape" ] [] ] ] ]


check : Html msg
check =
    iconView <|
        svg [ width "19px", height "14px", viewBox "0 0 19 14", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "check", transform "translate(2.000000, 2.000000)", stroke "#38C172", strokeWidth "3" ] [ polyline [ id "Shape", points "15 0 4.6875 10 0 5.45454545" ] [] ] ] ]


checkSquare : Html msg
checkSquare =
    iconView <|
        svg [ width "21px", height "20px", viewBox "0 0 21 20", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "check-square", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ polyline [ id "Shape", points "6 8 9 11 19 1" ] [], Svg.path [ d "M18,9 L18,16 C18,17.1045695 17.1045695,18 16,18 L2,18 C0.8954305,18 0,17.1045695 0,16 L0,2 C0,0.8954305 0.8954305,0 2,0 L13,0", id "Shape" ] [] ] ] ]


chevronDown : Html msg
chevronDown =
    iconView <|
        svg [ width "12px", height "7px", viewBox "0 0 12 7", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "chevron-down", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ polyline [ id "Path", points "0 0 5 5 10 0" ] [] ] ] ]


chevronRight : Html msg
chevronRight =
    iconView <|
        svg [ width "9px", height "16px", viewBox "0 0 9 16", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "chevrons-right", transform "translate(1.500000, 2.000000)", stroke "#4B73E1", strokeWidth "3" ] [ polyline [ id "Path", points "0 12 6 6 0 0" ] [] ] ] ]


chevronUp : Html msg
chevronUp =
    iconView <|
        svg [ width "12px", height "7px", viewBox "0 0 12 7", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "chevron-up", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ polyline [ id "Path", points "10 5 5 0 0 5" ] [] ] ] ]


closedAvatar : Html msg
closedAvatar =
    iconView <|
        svg [ width "36px", height "36px", viewBox "0 0 36 36", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd" ] [ g [ id "closed-avatar-2-copy", stroke "#38C172" ] [ circle [ id "Oval-2", cx "18", cy "18", r "17.5" ] [], g [ id "check", transform "translate(10.000000, 13.000000)", strokeLinecap "round", strokeLinejoin "round", strokeWidth "2" ] [ polyline [ id "Shape", points "16 0 5 11 0 6" ] [] ] ] ] ]


edit : Html msg
edit =
    iconView <|
        svg [ width "17px", height "17px", viewBox "0 0 17 17", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "edit", transform "translate(1.000000, 1.000000)", stroke "#c6ced2", strokeWidth "2" ] [ Svg.path [ d "M14.4,8.128 L14.4,13.4 C14.4,14.2836556 13.6836556,15 12.8,15 L1.6,15 C0.7163444,15 0,14.2836556 0,13.4 L0,2.2 C-1.77635684e-16,1.3163444 0.7163444,0.6 1.6,0.6 L5.872,0.6", id "Path" ] [], polygon [ id "Path", fill "#c6ced2", points "14 2.98431373 6.78431373 10.2 4.8 10.2 4.8 8.21568627 12.0156863 1" ] [] ] ] ]


eye : Toggle -> Html msg
eye toggle =
    case toggle of
        Off ->
            iconView <|
                svg [ width "20px", height "18px", viewBox "0 0 20 18", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "eye-off", transform "translate(1.000000, 0.000000)", stroke "#8A98A5" ] [ Svg.path [ d "M13.86,13.86 C12.4613918,14.9260927 10.7583607,15.5167062 9,15.5454545 C3.27272727,15.5454545 0,9 0,9 C1.0177281,7.10336918 2.42929264,5.44631515 4.14,4.14 M7.28181818,2.65090909 C7.84499916,2.51908324 8.42159788,2.45318624 9,2.45454545 C14.7272727,2.45454545 18,9 18,9 C17.5033469,9.92913329 16.9110453,10.803875 16.2327273,11.61 M10.7345455,10.7345455 C10.1226417,11.3912286 9.20109095,11.6615428 8.33141812,11.4394436 C7.46174528,11.2173444 6.78265559,10.5382547 6.56055641,9.66858188 C6.33845722,8.79890905 6.60877142,7.87735826 7.26545455,7.26545455", id "Shape" ] [], Svg.path [ d "M0,0 L18,18", id "Path" ] [] ] ] ]

        On ->
            iconView <|
                svg [ width "20px", height "15px", viewBox "0 0 20 15", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "eye", transform "translate(1.000000, 1.000000)", fill "#8A98A5" ] [ Svg.path [ d "M0,6.5 C0,6.5 3.27272727,0 9,0 C14.7272727,0 18,6.5 18,6.5 C18,6.5 14.7272727,13 9,13 C3.27272727,13 0,6.5 0,6.5 Z", id "Path", stroke "#8A98A5" ] [], ellipse [ id "Oval", stroke "#FFFFFF", strokeWidth "2", cx "9", cy "6.5", rx "2.45454545", ry "2.4375" ] [] ] ] ]


file : Color -> Html msg
file strokeColor =
    iconView <|
        svg [ width "13px", height "16px", viewBox "0 0 13 16", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "file", transform "translate(0.500000, 0.500000)", stroke "#8A98A5" ] [ Svg.path [ d "M6.75,0 L1.5,0 C0.671572875,0 0,0.671572875 0,1.5 L0,13.5 C0,14.3284271 0.671572875,15 1.5,15 L10.5,15 C11.3284271,15 12,14.3284271 12,13.5 L12,5.25 L6.75,0 Z", id "Shape" ] [], polyline [ id "Shape", points "6.75 0 6.75 5.25 12 5.25" ] [] ] ] ]


filter : Html msg
filter =
    iconView <|
        svg [ width "19px", height "17px", viewBox "0 0 19 17", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "filter", transform "translate(1.000000, 1.000000)", stroke "#FFFFFF", strokeWidth "2" ] [ polygon [ id "Shape", points "17 0 0 0 6.8 7.88333333 6.8 13.3333333 10.2 15 10.2 7.88333333" ] [] ] ] ]


image : Color -> Html msg
image strokeColor =
    iconView <|
        svg [ width "16px", height "16px", viewBox "0 0 16 16", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "image-copy", transform "translate(0.500000, 0.500000)", stroke "#8A98A5" ] [ rect [ id "Rectangle-path", x "0", y "0", width "15", height "15", rx "2" ] [], circle [ id "Oval", cx "4.58333333", cy "4.58333333", r "1.25" ] [], polyline [ id "Shape", points "15 10 10.8333333 5.83333333 1.66666667 15" ] [] ] ] ]


inboxWhite : Html msg
inboxWhite =
    iconView <|
        svg [ width "17px", height "14px", viewBox "0 0 17 14", version "1.1" ] [ desc [] [ text "Created with Sketch." ], defs [] [], g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "inbox", transform "translate(1.000000, 1.000000)", stroke "#fff", strokeWidth "2" ] [ Svg.path [ d "M15,6 L12.4125,0.8325 C12.1592025,0.322756741 11.639208,0.000302043969 11.07,0 L3.93,0 C3.36079202,0.000302043969 2.84079751,0.322756741 2.5875,0.8325 L0,6", id "Shape" ] [], Svg.path [ d "M10.5,6 L15,6 L15,10.5 C15,11.3284271 14.3284271,12 13.5,12 L1.5,12 C0.671572875,12 0,11.3284271 0,10.5 L0,6 L4.5,6 L6,8.25 L9,8.25 L10.5,6 Z", id "Combined-Shape", fill "#fff" ] [] ] ] ]


inbox : Toggle -> Html msg
inbox toggle =
    case toggle of
        On ->
            iconView <|
                svg [ width "16px", height "13px", viewBox "0 0 16 13", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "inbox", transform "translate(0.500000, 0.500000)", stroke "#38C172" ] [ Svg.path [ d "M15,6 L12.4125,0.8325 C12.1592025,0.322756741 11.639208,0.000302043969 11.07,0 L3.93,0 C3.36079202,0.000302043969 2.84079751,0.322756741 2.5875,0.8325 L0,6", id "Shape" ] [], Svg.path [ d "M10.5,6 L15,6 L15,10.5 C15,11.3284271 14.3284271,12 13.5,12 L1.5,12 C0.671572875,12 0,11.3284271 0,10.5 L0,6 L4.5,6 L6,8.25 L9,8.25 L10.5,6 Z", id "Combined-Shape", fill "#38C172" ] [] ] ] ]

        Off ->
            iconView <|
                svg [ width "16px", height "13px", viewBox "0 0 16 13", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "inbox", transform "translate(0.500000, 0.500000)", stroke "#8A98A5" ] [ Svg.path [ d "M15,6 L12.4125,0.8325 C12.1592025,0.322756741 11.639208,0.000302043969 11.07,0 L3.93,0 C3.36079202,0.000302043969 2.84079751,0.322756741 2.5875,0.8325 L0,6", id "Shape" ] [], Svg.path [ d "M10.5,6 L15,6 L15,10.5 C15,11.3284271 14.3284271,12 13.5,12 L1.5,12 C0.671572875,12 0,11.3284271 0,10.5 L0,6 L4.5,6 L6,8.25 L9,8.25 L10.5,6 Z", id "Combined-Shape" ] [] ] ] ]


logOut : Html msg
logOut =
    iconView <|
        svg [ width "20px", height "20px", viewBox "0 0 20 20", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "log-out", transform "translate(10.000000, 10.000000) scale(-1, 1) translate(-10.000000, -10.000000) translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M6,18 L2,18 C0.8954305,18 0,17.1045695 0,16 L0,2 C0,0.8954305 0.8954305,0 2,0 L6,0", id "Shape" ] [], polyline [ id "Shape", points "13 14 18 9 13 4" ] [], Svg.path [ d "M18,9 L6,9", id "Shape" ] [] ] ] ]


menu : Html msg
menu =
    iconView <|
        svg [ width "16px", height "12px", viewBox "0 0 16 12", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "menu", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M0,5 L14,5", id "Shape" ] [], Svg.path [ d "M0,0 L14,0", id "Shape" ] [], Svg.path [ d "M0,10 L14,10", id "Shape" ] [] ] ] ]


more : Html msg
more =
    iconView <|
        svg [ width "18px", height "4px", viewBox "0 0 18 4", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "more-horizontal", transform "translate(1.000000, 1.000000)", stroke "#8A98A5" ] [ circle [ id "Oval", cx "8", cy "1", r "1" ] [], circle [ id "Oval", cx "15", cy "1", r "1" ] [], circle [ id "Oval", cx "1", cy "1", r "1" ] [] ] ] ]


{-| Using the `circle` feather icon.
-}
open : Html msg
open =
    iconView <|
        svg [ width "22px", height "22px", viewBox "0 0 22 22", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "circle", transform "translate(1.000000, 1.000000)", stroke "#11E72B", strokeWidth "2" ] [ circle [ id "Oval", cx "10", cy "10", r "10" ] [] ] ] ]


{-| Using the `check-circle` feather icon.
-}
closed : Html msg
closed =
    iconView <|
        svg [ width "22px", height "22px", viewBox "0 0 22 22", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "check-circle", transform "translate(1.000000, 0.000000)", stroke "#FF1E12", strokeWidth "2" ] [ Svg.path [ d "M20,10.08 L20,11 C19.9974678,15.4286859 17.082294,19.328213 12.8353524,20.583901 C8.58841086,21.839589 4.02139355,20.1523121 1.61095509,16.4370663 C-0.799483376,12.7218205 -0.479136554,7.86363898 2.39827419,4.49707214 C5.27568494,1.13050531 10.0247126,0.0575252842 14.07,1.86", id "Shape" ] [], polyline [ id "Shape", points "20 3 10 13.01 7 10.01" ] [] ] ] ]


closedSmall : Html msg
closedSmall =
    iconView <|
        svg [ width "16px", height "16px", viewBox "0 0 16 16", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd" ] [ g [ id "closed-avatar-2-copy-4" ] [ circle [ id "Oval-2", fill "#38C172", cx "8", cy "8", r "8" ] [], g [ id "check", transform "translate(4.444444, 5.777778)", stroke "#FFFFFF", strokeLinecap "round", strokeLinejoin "round", strokeWidth "2" ] [ polyline [ id "Shape", points "7.11111111 0 2.22222222 4.88888889 0 2.66666667" ] [] ] ] ] ]


comment : Html msg
comment =
    iconView <|
        svg [ width "16px", height "16px", viewBox "0 0 16 16", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "message-square-copy", transform "translate(1.000000, 1.000000)", fill "#c6ced2", stroke "#c6ced2", strokeWidth "2" ] [ Svg.path [ d "M14,9.33333333 C14,10.1924429 13.3035541,10.8888889 12.4444444,10.8888889 L3.11111111,10.8888889 L0,14 L0,1.55555556 C0,0.696445945 0.696445945,0 1.55555556,0 L12.4444444,0 C13.3035541,0 14,0.696445945 14,1.55555556 L14,9.33333333 Z", id "Shape" ] [] ] ] ]


commentWhite : Html msg
commentWhite =
    iconView <|
        svg [ width "26px", height "26px", viewBox "0 0 26 26", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "message-square-copy", transform "translate(1.000000, 1.000000)", fill "#FFFFFF", stroke "#FFFFFF", strokeWidth "2" ] [ Svg.path [ d "M24,16 C24,17.4727593 22.8060927,18.6666667 21.3333333,18.6666667 L5.33333333,18.6666667 L0,24 L0,2.66666667 C0,1.19390733 1.19390733,0 2.66666667,0 L21.3333333,0 C22.8060927,0 24,1.19390733 24,2.66666667 L24,16 Z", id "Shape" ] [] ] ] ]


hash : Html msg
hash =
    iconView <|
        svg [ width "16px", height "18px", viewBox "0 0 16 18", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "hash", transform "translate(1.000000, 1.000000)", stroke "#4B73E1", strokeWidth "2" ] [ Svg.path [ d "M0,5.33333333 L14,5.33333333", id "Path" ] [], Svg.path [ d "M0,10.6666667 L14,10.6666667", id "Path" ] [], Svg.path [ d "M5.25,0 L3.5,16", id "Path" ] [], Svg.path [ d "M10.5,0 L8.75,16", id "Path" ] [] ] ] ]


heart : Html msg
heart =
    iconView <|
        svg [ width "20px", height "17px", viewBox "0 0 20 17", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "heart", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M15.7837833,1.2894605 C14.939809,0.463853671 13.7948962,-7.10542736e-16 12.601056,0 C11.4072158,3.55271368e-16 10.2623031,0.463853671 9.41832875,1.2894605 L8.55105603,2.1374605 L7.6837833,1.2894605 C5.92601156,-0.429249601 3.07610052,-0.42924958 1.3183288,1.28946054 C-0.439442915,3.00817067 -0.439442937,5.79475035 1.31832875,7.5134605 L2.18560148,8.3614605 L8.55105603,14.5854605 L14.9165106,8.3614605 L15.7837833,7.5134605 C16.6281539,6.68824114 17.1025497,5.56877092 17.1025497,4.4014605 C17.1025497,3.23415007 16.6281539,2.11467986 15.7837833,1.2894605 Z", id "Shape" ] [] ] ] ]


home : Toggle -> Html msg
home toggle =
    case toggle of
        On ->
            iconView <|
                svg [ width "20px", height "22px", viewBox "0 0 20 22", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "home", transform "translate(1.000000, 1.000000)", fill "#4b73e1", stroke "#4b73e1", strokeWidth "2" ] [ Svg.path [ d "M12,20 L12,10 L6,10 L6,20 L2,20 C0.8954305,20 0,19.1045695 0,18 L0,7 L9,0 L18,7 L18,18 C18,19.1045695 17.1045695,20 16,20 L12,20 Z", id "Combined-Shape" ] [] ] ] ]

        Off ->
            iconView <|
                svg [ width "20px", height "22px", viewBox "0 0 20 22", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "home", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M12,20 L12,10 L6,10 L6,20 L2,20 C0.8954305,20 0,19.1045695 0,18 L0,7 L9,0 L18,7 L18,18 C18,19.1045695 17.1045695,20 16,20 L12,20 Z", id "Combined-Shape" ] [] ] ] ]


lock : Html msg
lock =
    iconView <|
        svg [ width "10px", height "12px", viewBox "0 0 10 12", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "lock", transform "translate(0.500000, 0.500000)", stroke "#8A98A5" ] [ rect [ id "Rectangle-path", fill "#8A98A5", x "0", y "4.95", width "9", height "6.05", rx "2" ] [], Svg.path [ d "M2,4.95 L2,2.75 C2,1.23121694 3.11928813,1.13242749e-15 4.5,8.8817842e-16 C5.88071187,3.99680289e-16 7,1.23121694 7,2.75 L7,4.95", id "Shape" ] [] ] ] ]


lockLarge : Html msg
lockLarge =
    iconView <|
        svg [ width "15px", height "17px", viewBox "0 0 15 17", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "lock-copy", transform "translate(0.500000, 0.500000)", stroke "#8A98A5" ] [ rect [ id "Rectangle-path", fill "#8A98A5", x "0", y "7.2", width "14", height "8.8", rx "2" ] [], Svg.path [ d "M3.11111111,7.2 L3.11111111,4 C3.11111111,1.790861 4.85222597,1.24344979e-15 7,8.8817842e-16 C9.14777403,1.77635684e-16 10.8888889,1.790861 10.8888889,4 L10.8888889,7.2", id "Shape" ] [] ] ] ]


logo : Html msg
logo =
    svg [ width "99px", height "20px", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd" ] [ g [ transform "translate(-661.000000, -131.000000)" ] [ g [ transform "translate(661.000000, 131.000000)" ] [ Svg.path [ d "M7,1 L23,1 C24.1045695,1 25,1.8954305 25,3 C25,4.1045695 24.1045695,5 23,5 L7,5 C5.8954305,5 5,4.1045695 5,3 C5,1.8954305 5.8954305,1 7,1 Z M12,8 L28,8 C29.1045695,8 30,8.8954305 30,10 C30,11.1045695 29.1045695,12 28,12 L12,12 C10.8954305,12 10,11.1045695 10,10 C10,8.8954305 10.8954305,8 12,8 Z M2,15 L18,15 C19.1045695,15 20,15.8954305 20,17 C20,18.1045695 19.1045695,19 18,19 L2,19 C0.8954305,19 1.3527075e-16,18.1045695 0,17 C-1.3527075e-16,15.8954305 0.8954305,15 2,15 Z", fill "#12C1D5" ] [], Svg.path [ d "M38,17.8074866 L38,2.03208556 C38,0.909090909 38.9144621,0 40.0440917,0 C41.1737213,0 42.0881834,0.909090909 42.0881834,2.03208556 L42.0881834,17.8074866 C42.0881834,18.9304813 41.1737213,19.8395722 40.0440917,19.8395722 C38.9144621,19.8395722 38,18.9304813 38,17.8074866 Z M57.7685185,18.2620321 C56.5044092,19.3315508 54.8637566,20 52.765873,20 C48.4356261,20 45.2350088,16.9786096 45.2350088,12.5935829 L45.2350088,12.540107 C45.2350088,8.44919786 48.1666667,5.0802139 52.3624339,5.0802139 C57.1768078,5.0802139 59.3015873,9.01069519 59.3015873,11.9786096 C59.3015873,13.1550802 58.4678131,13.9304813 57.3919753,13.9304813 L49.2962963,13.9304813 C49.6997354,15.7754011 50.9907407,16.7379679 52.8196649,16.7379679 C53.9492945,16.7379679 54.8906526,16.3903743 55.7244268,15.7754011 C56.0202822,15.5614973 56.2892416,15.4545455 56.7195767,15.4545455 C57.6340388,15.4545455 58.3064374,16.1497326 58.3064374,17.0588235 C58.3064374,17.5935829 58.0643739,17.9946524 57.7685185,18.2620321 Z M49.2425044,11.3903743 L55.4016755,11.3903743 C55.159612,9.57219251 54.0837743,8.34224599 52.3624339,8.34224599 C50.6679894,8.34224599 49.5652557,9.54545455 49.2425044,11.3903743 Z M70.9206349,18.2085561 C70.4634039,19.2513369 69.7103175,19.973262 68.6075838,19.973262 L68.3924162,19.973262 C67.2896825,19.973262 66.5365961,19.2780749 66.0793651,18.2085561 L61.6684303,8.07486631 C61.5608466,7.80748663 61.4532628,7.45989305 61.4532628,7.0855615 C61.4532628,6.12299465 62.3408289,5.18716578 63.4435626,5.18716578 C64.5462963,5.18716578 65.1380071,5.80213904 65.4338624,6.63101604 L68.5268959,14.9465241 L71.6737213,6.57754011 C71.9426808,5.88235294 72.5074956,5.18716578 73.5833333,5.18716578 C74.6591711,5.18716578 75.5467372,6.01604278 75.5467372,7.11229947 C75.5467372,7.45989305 75.4122575,7.88770053 75.3315697,8.07486631 L70.9206349,18.2085561 Z M90.0705467,18.2620321 C88.8064374,19.3315508 87.1657848,20 85.0679012,20 C80.7376543,20 77.537037,16.9786096 77.537037,12.5935829 L77.537037,12.540107 C77.537037,8.44919786 80.4686949,5.0802139 84.6644621,5.0802139 C89.478836,5.0802139 91.6036155,9.01069519 91.6036155,11.9786096 C91.6036155,13.1550802 90.7698413,13.9304813 89.6940035,13.9304813 L81.5983245,13.9304813 C82.0017637,15.7754011 83.292769,16.7379679 85.1216931,16.7379679 C86.2513228,16.7379679 87.1926808,16.3903743 88.026455,15.7754011 C88.3223104,15.5614973 88.5912698,15.4545455 89.0216049,15.4545455 C89.936067,15.4545455 90.6084656,16.1497326 90.6084656,17.0588235 C90.6084656,17.5935829 90.3664021,17.9946524 90.0705467,18.2620321 Z M81.5445326,11.3903743 L87.7037037,11.3903743 C87.4616402,9.57219251 86.3858025,8.34224599 84.6644621,8.34224599 C82.9700176,8.34224599 81.867284,9.54545455 81.5445326,11.3903743 Z M94.9118166,17.8074866 L94.9118166,2.03208556 C94.9118166,0.909090909 95.8262787,0 96.9559083,0 C98.0855379,0 99,0.909090909 99,2.03208556 L99,17.8074866 C99,18.9304813 98.0855379,19.8395722 96.9559083,19.8395722 C95.8262787,19.8395722 94.9118166,18.9304813 94.9118166,17.8074866 Z", id "level", fill "#22384C" ] [] ] ] ] ]


logomark : Html msg
logomark =
    iconView <|
        svg [ width "36px", height "36px", viewBox "0 0 36 36", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd" ] [ Svg.path [ d "M18,36 C8.0588745,36 0,27.9411255 0,18 C0,8.0588745 8.0588745,0 18,0 C27.9411255,0 36,8.0588745 36,18 C36,27.9411255 27.9411255,36 18,36 Z M12.6,11 C11.7163444,11 11,11.7163444 11,12.6 C11,13.4836556 11.7163444,14.2 12.6,14.2 L25.4,14.2 C26.2836556,14.2 27,13.4836556 27,12.6 C27,11.7163444 26.2836556,11 25.4,11 L12.6,11 Z M16.6,16.6 C15.7163444,16.6 15,17.3163444 15,18.2 C15,19.0836556 15.7163444,19.8 16.6,19.8 L29.4,19.8 C30.2836556,19.8 31,19.0836556 31,18.2 C31,17.3163444 30.2836556,16.6 29.4,16.6 L16.6,16.6 Z M8.6,22.2 C7.7163444,22.2 7,22.9163444 7,23.8 C7,24.6836556 7.7163444,25.4 8.6,25.4 L21.4,25.4 C22.2836556,25.4 23,24.6836556 23,23.8 C23,22.9163444 22.2836556,22.2 21.4,22.2 L8.6,22.2 Z", id "Combined-Shape", fill "#12C1D5", fillRule "nonzero" ] [] ] ]


plus : Toggle -> Html msg
plus toggle =
    case toggle of
        On ->
            iconView <|
                svg [ width "18px", height "18px", viewBox "0 0 18 18", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "plus-copy", transform "translate(1.000000, 1.000000)", stroke "#4b73e1", strokeWidth "2" ] [ Svg.path [ d "M8,0 L8,16", id "Path" ] [], Svg.path [ d "M0,8 L16,8", id "Path" ] [] ] ] ]

        Off ->
            iconView <|
                svg [ width "18px", height "18px", viewBox "0 0 18 18", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "plus-copy", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M8,0 L8,16", id "Path" ] [], Svg.path [ d "M0,8 L16,8", id "Path" ] [] ] ] ]


postbot : Html msg
postbot =
    iconView <|
        svg [ width "48px", height "48px", viewBox "0 0 48 48", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd" ] [ g [ id "postbot-icon" ] [ circle [ id "Oval", fill "#50667A", fillRule "nonzero", cx "24", cy "24", r "24" ] [], g [ id "code", transform "translate(14.400000, 18.400000)", stroke "#FFFFFF", strokeLinecap "round", strokeLinejoin "round", strokeWidth "2" ] [ polyline [ id "Path", points "13.44 11.52 19.2 5.76 13.44 0" ] [], polyline [ id "Path", points "5.76 0 0 5.76 5.76 11.52" ] [] ] ] ] ]


reply : Html msg
reply =
    Html.div [ Html.Attributes.class "flex items-center", Html.Attributes.style "margin-top" "2px" ]
        [ svg [ width "17px", height "16px", viewBox "0 0 17 16", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "corner-up-left", transform "translate(0.500000, 0.500000)", stroke "#8A98A5" ] [ polyline [ id "Path", points "5 10 0 5 5 0" ] [], Svg.path [ d "M16,15 L16,8.63636364 C16,6.62805546 14.209139,5 12,5 L0,5", id "Path" ] [] ] ] ] ]


refresh : Html msg
refresh =
    iconView <|
        svg [ width "19px", height "16px", viewBox "0 0 19 16", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "refresh-cw", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ polyline [ id "Shape", points "16.6000004 0.754545452 16.6000004 5.28181816 12.0727276 5.28181816" ] [], polyline [ id "Shape", points "0 12.8272727 0 8.29999997 4.52727283 8.29999997" ] [], Svg.path [ d "M1.89390913,4.52727271 C2.6717562,2.32913969 4.52294715,0.683782855 6.79716195,0.169213054 C9.07137676,-0.345356747 11.4505602,0.342824506 13.0989094,1.99199999 L16.6000004,5.28181816 M0,8.29999997 L3.50109099,11.5898181 C5.14944021,13.2389936 7.52862362,13.9271749 9.80283843,13.4126051 C12.0770532,12.8980353 13.9282442,11.2526784 14.7060912,9.05454542", id "Shape" ] [] ] ] ]


revokeMember : Html msg
revokeMember =
    iconView <|
        svg [ width "24px", height "20px", viewBox "0 0 24 20", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "user-x", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M15,18 L15,16 C15,13.790861 13.209139,12 11,12 L4,12 C1.790861,12 2.22044605e-16,13.790861 0,16 L0,18", id "Shape" ] [], circle [ id "Oval", cx "7.5", cy "4", r "4" ] [], Svg.path [ d "M17,5 L22,10", id "Shape" ] [], Svg.path [ d "M22,5 L17,10", id "Shape" ] [] ] ] ]


search : Html msg
search =
    iconView <|
        svg [ width "18px", height "18px", viewBox "0 0 18 18", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "search", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ circle [ id "Oval", cx "7.11111111", cy "7.11111111", r "7.11111111" ] [], Svg.path [ d "M16,16 L12.1333333,12.1333333", id "Path" ] [] ] ] ]


sendWhite : Html msg
sendWhite =
    iconView <|
        svg [ width "18px", height "18px", viewBox "0 0 18 18", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd" ] [ g [ id "send", transform "translate(0.000000, -5.000000)", fill "#FFFFFF", fillRule "nonzero" ] [ Svg.path [ d "M3.30681649,3.30681649 L19.3068165,11.3068165 L3.30681649,19.3068165 L3.30681649,3.30681649 Z M3.30681649,9.70681649 L3.30681649,12.9068165 L11.3068165,11.3068165 L3.30681649,9.70681649 Z", id "Shape", transform "translate(11.306816, 11.306816) rotate(-43.000000) translate(-11.306816, -11.306816) " ] [] ] ] ]


settings : Html msg
settings =
    iconView <|
        svg [ width "20px", height "20px", viewBox "0 0 20 20", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "settings", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M15.0545455,11.4545455 C14.8317165,11.9594373 14.938637,12.5491199 15.3245455,12.9436364 L15.3736364,12.9927273 C15.6809079,13.2996571 15.85356,13.7161485 15.85356,14.1504545 C15.85356,14.5847606 15.6809079,15.0012519 15.3736364,15.3081818 C15.0667065,15.6154533 14.6502151,15.7881054 14.2159091,15.7881054 C13.781603,15.7881054 13.3651117,15.6154533 13.0581818,15.3081818 L13.0090909,15.2590909 C12.6145745,14.8731825 12.0248919,14.766262 11.52,14.9890909 C11.0254331,15.2010559 10.7039642,15.686474 10.7018182,16.2245455 L10.7018182,16.3636364 C10.7018182,17.267375 9.96919323,18 9.06545455,18 C8.16171586,18 7.42909091,17.267375 7.42909091,16.3636364 L7.42909091,16.29 C7.41612813,15.7358216 7.06571327,15.2458897 6.54545455,15.0545455 C6.04056267,14.8317165 5.45088006,14.938637 5.05636364,15.3245455 L5.00727273,15.3736364 C4.70034285,15.6809079 4.2838515,15.85356 3.84954545,15.85356 C3.41523941,15.85356 2.99874806,15.6809079 2.69181818,15.3736364 C2.38454666,15.0667065 2.21189456,14.6502151 2.21189456,14.2159091 C2.21189456,13.781603 2.38454666,13.3651117 2.69181818,13.0581818 L2.74090909,13.0090909 C3.12681754,12.6145745 3.23373801,12.0248919 3.01090909,11.52 C2.79894413,11.0254331 2.31352603,10.7039642 1.77545455,10.7018182 L1.63636364,10.7018182 C0.732624955,10.7018182 1.81672859e-16,9.96919323 0,9.06545455 C-9.08364293e-17,8.16171586 0.732624955,7.42909091 1.63636364,7.42909091 L1.71,7.42909091 C2.26417842,7.41612813 2.75411031,7.06571327 2.94545455,6.54545455 C3.16828346,6.04056267 3.06136299,5.45088006 2.67545455,5.05636364 L2.62636364,5.00727273 C2.31909211,4.70034285 2.14644002,4.2838515 2.14644002,3.84954545 C2.14644002,3.41523941 2.31909211,2.99874806 2.62636364,2.69181818 C2.93329351,2.38454666 3.34978487,2.21189456 3.78409091,2.21189456 C4.21839695,2.21189456 4.63488831,2.38454666 4.94181818,2.69181818 L4.99090909,2.74090909 C5.38542551,3.12681754 5.97510812,3.23373801 6.48,3.01090909 L6.54545455,3.01090909 C7.04002141,2.79894413 7.36149035,2.31352603 7.36363636,1.77545455 L7.36363636,1.63636364 C7.36363636,0.732624955 8.09626132,1.81672859e-16 9,0 C9.90373868,0 10.6363636,0.732624955 10.6363636,1.63636364 L10.6363636,1.71 C10.6385096,2.24807148 10.9599786,2.73348959 11.4545455,2.94545455 C11.9594373,3.16828346 12.5491199,3.06136299 12.9436364,2.67545455 L12.9927273,2.62636364 C13.2996571,2.31909211 13.7161485,2.14644002 14.1504545,2.14644002 C14.5847606,2.14644002 15.0012519,2.31909211 15.3081818,2.62636364 C15.6154533,2.93329351 15.7881054,3.34978487 15.7881054,3.78409091 C15.7881054,4.21839695 15.6154533,4.63488831 15.3081818,4.94181818 L15.2590909,4.99090909 C14.8731825,5.38542551 14.766262,5.97510812 14.9890909,6.48 L14.9890909,6.54545455 C15.2010559,7.04002141 15.686474,7.36149035 16.2245455,7.36363636 L16.3636364,7.36363636 C17.267375,7.36363636 18,8.09626132 18,9 C18,9.90373868 17.267375,10.6363636 16.3636364,10.6363636 L16.29,10.6363636 C15.7519285,10.6385096 15.2665104,10.9599786 15.0545455,11.4545455 Z M9,11.5 C10.3807119,11.5 11.5,10.3807119 11.5,9 C11.5,7.61928813 10.3807119,6.5 9,6.5 C7.61928813,6.5 6.5,7.61928813 6.5,9 C6.5,10.3807119 7.61928813,11.5 9,11.5 Z", id "Combined-Shape" ] [] ] ] ]


shield : Html msg
shield =
    iconView <|
        svg [ width "17px", height "21px", viewBox "0 0 17 21", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "shield", transform "translate(0.500000, 0.500000)", stroke "#8A98A5" ] [ Svg.path [ d "M8,20 C8,20 16,16 16,10 L16,3 L8,0 L0,3 L0,10 C0,16 8,20 8,20 Z", id "Path" ] [] ] ] ]


square : Html msg
square =
    iconView <|
        svg [ width "20px", height "20px", viewBox "0 0 20 20", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "square", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ rect [ id "Rectangle-path", x "0", y "0", width "18", height "18", rx "2" ] [] ] ] ]


thumbs : Toggle -> Html msg
thumbs toggle =
    case toggle of
        On ->
            iconView <|
                svg [ width "21px", height "19px", viewBox "0 0 21 19", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "thumbs-up-copy-3", transform "translate(1.000000, 0.000000)", fill "#38C172", stroke "#38C172" ] [ Svg.path [ d "M10.0949707,7.74995624 L10.7758789,3.04650879 C10.7758789,1.80387616 10.187236,0.515136719 8.92456055,0.515136719 C8.34004575,3.14353758 7.78845069,4.99770425 7.26977539,6.07763672 C6.88020833,6.88875326 6.05944824,7.54593913 4.80749512,8.04919434 C4.63909245,9.3850804 4.57671452,10.6972956 4.62036133,11.9858398 C4.66400813,13.2743841 4.85158951,14.5544541 5.18310547,15.8260498 C7.63919702,16.7598855 9.50345483,17.3019184 10.7758789,17.4521484 C12.4725342,17.6524658 13.1655273,17.6524658 14.8193359,17.651123 C16.4731445,17.6497803 16.9049072,16.8726232 16.9049072,16.1645508 C16.9049072,15.4564784 16.6865234,15.5007324 16.4108887,14.9851074 C16.9019048,14.673584 18.0416976,13.7696931 18.105957,13.4697266 C18.3126102,12.5050581 17.6384277,12.2376709 17.1776123,11.6315918 C17.6317139,11.230835 18.5894406,10.5868489 18.6437988,10.1862793 C18.7086365,9.70848604 17.5094579,8.88317871 17.1776123,8.56494141 C17.5094579,8.18774414 18.0452854,7.46174169 18.105957,7.01464844 C18.1666286,6.56755518 17.654541,6.24924058 17.1776123,6.16918945 C16.7006836,6.08913833 15.6947021,6.16918945 14.3764648,6.49047852 C13.49764,6.70467122 12.0704753,7.12449713 10.0949707,7.74995624 Z", id "Shape" ] [], Svg.path [ d "M3,15.6876221 L1.46005249,15.4832153 C0.797375728,15.3687744 0.48260498,14.9857847 0.319580078,14.357666 C0.156555176,13.7295474 2.72892049e-17,13.0910645 0,11.8841553 C0,10.6772461 0.184387207,9.828125 0.319580078,9.2467041 C0.454772949,8.6652832 0.689147949,8.25402832 1.29213233,8.14337158 L2.76300049,8 C2.54315186,9.34279219 2.43322754,10.6375106 2.43322754,11.8841553 C2.43322754,13.1307999 2.62215169,14.3986222 3,15.6876221 Z", id "Path" ] [] ] ] ]

        Off ->
            iconView <|
                svg [ width "21px", height "19px", viewBox "0 0 21 19", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "thumbs-up-copy-2", transform "translate(1.000000, 0.000000)", stroke "#8A98A5" ] [ Svg.path [ d "M10.0949707,7.74995624 L10.7758789,3.04650879 C10.7758789,1.80387616 10.187236,0.515136719 8.92456055,0.515136719 C8.34004575,3.14353758 7.78845069,4.99770425 7.26977539,6.07763672 C6.88020833,6.88875326 6.05944824,7.54593913 4.80749512,8.04919434 C4.63909245,9.3850804 4.57671452,10.6972956 4.62036133,11.9858398 C4.66400813,13.2743841 4.85158951,14.5544541 5.18310547,15.8260498 C7.63919702,16.7598855 9.50345483,17.3019184 10.7758789,17.4521484 C12.4725342,17.6524658 13.1655273,17.6524658 14.8193359,17.651123 C16.4731445,17.6497803 16.9049072,16.8726232 16.9049072,16.1645508 C16.9049072,15.4564784 16.6865234,15.5007324 16.4108887,14.9851074 C16.9019048,14.673584 18.0416976,13.7696931 18.105957,13.4697266 C18.3126102,12.5050581 17.6384277,12.2376709 17.1776123,11.6315918 C17.6317139,11.230835 18.5894406,10.5868489 18.6437988,10.1862793 C18.7086365,9.70848604 17.5094579,8.88317871 17.1776123,8.56494141 C17.5094579,8.18774414 18.0452854,7.46174169 18.105957,7.01464844 C18.1666286,6.56755518 17.654541,6.24924058 17.1776123,6.16918945 C16.7006836,6.08913833 15.6947021,6.16918945 14.3764648,6.49047852 C13.49764,6.70467122 12.0704753,7.12449713 10.0949707,7.74995624 Z", id "Shape" ] [], Svg.path [ d "M3,15.6876221 L1.46005249,15.4832153 C0.797375728,15.3687744 0.48260498,14.9857847 0.319580078,14.357666 C0.156555176,13.7295474 2.72892049e-17,13.0910645 0,11.8841553 C0,10.6772461 0.184387207,9.828125 0.319580078,9.2467041 C0.454772949,8.6652832 0.689147949,8.25402832 1.29213233,8.14337158 L2.76300049,8 C2.54315186,9.34279219 2.43322754,10.6375106 2.43322754,11.8841553 C2.43322754,13.1307999 2.62215169,14.3986222 3,15.6876221 Z", id "Path" ] [] ] ] ]


thumbsMedium : Toggle -> Html msg
thumbsMedium toggle =
    case toggle of
        On ->
            iconView <|
                svg [ width "18px", height "17px", viewBox "0 0 18 17", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "thumbs-up-copy-6", transform "translate(0.500000, 0.500000)", fill "#38C172", stroke "#38C172" ] [ Svg.path [ d "M9.03234221,6.88884999 L9.64157586,2.70800781 C9.64157586,1.60344547 9.11489535,0.457899306 7.98513312,0.457899306 C7.46214619,2.79425563 6.96861378,4.44240377 6.50453588,5.40234375 C6.15597588,6.12333623 5.42161159,6.70750145 4.301443,7.15483941 C4.15076693,8.34229369 4.0949551,9.50870717 4.1340075,10.6540799 C4.17305991,11.7994526 4.34089588,12.9372925 4.63751542,14.0675998 C6.83507102,14.897676 8.50309116,15.379483 9.64157586,15.5130208 C11.1596358,15.6910807 11.7796824,15.6910807 13.2594058,15.6898872 C14.7391293,15.6886936 15.1254433,14.9978873 15.1254433,14.3684896 C15.1254433,13.7390919 14.9300473,13.7784288 14.6834267,13.3200955 C15.122757,13.0431858 16.1425715,12.2397272 16.2000668,11.9730903 C16.384967,11.1156072 15.7817511,10.8779297 15.3694426,10.3391927 C15.775744,9.98296441 16.6326574,9.41053232 16.6812937,9.05447049 C16.7393063,8.62976537 15.6663571,7.89615885 15.3694426,7.61328125 C15.6663571,7.27799479 16.1457817,6.63265928 16.2000668,6.23524306 C16.2543519,5.83782683 15.7961683,5.55488051 15.3694426,5.48372396 C14.9427169,5.4125674 14.0426282,5.48372396 12.8631528,5.76931424 C12.0768358,5.95970775 10.7998989,6.33288634 9.03234221,6.88884999 Z", id "Shape" ] [], Svg.path [ d "M2.68421053,13.944553 L1.30636275,13.7628581 C0.713441441,13.6611328 0.431804456,13.3206975 0.28594007,12.7623698 C0.140075684,12.2040421 2.4416657e-17,11.6365017 0,10.5636936 C0,9.49088542 0.164978027,8.73611111 0.28594007,8.21929253 C0.406902112,7.70247396 0.61660606,7.33691406 1.1561184,7.23855252 L2.47215833,7.11111111 C2.27545166,8.30470417 2.17709832,9.45556499 2.17709832,10.5636936 C2.17709832,11.6718222 2.34613573,12.7987753 2.68421053,13.944553 Z", id "Path" ] [] ] ] ]

        Off ->
            iconView <|
                svg [ width "18px", height "17px", viewBox "0 0 18 17", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "thumbs-up-copy-5", transform "translate(0.500000, 0.500000)", stroke "#8A98A5" ] [ Svg.path [ d "M9.03234221,6.88884999 L9.64157586,2.70800781 C9.64157586,1.60344547 9.11489535,0.457899306 7.98513312,0.457899306 C7.46214619,2.79425563 6.96861378,4.44240377 6.50453588,5.40234375 C6.15597588,6.12333623 5.42161159,6.70750145 4.301443,7.15483941 C4.15076693,8.34229369 4.0949551,9.50870717 4.1340075,10.6540799 C4.17305991,11.7994526 4.34089588,12.9372925 4.63751542,14.0675998 C6.83507102,14.897676 8.50309116,15.379483 9.64157586,15.5130208 C11.1596358,15.6910807 11.7796824,15.6910807 13.2594058,15.6898872 C14.7391293,15.6886936 15.1254433,14.9978873 15.1254433,14.3684896 C15.1254433,13.7390919 14.9300473,13.7784288 14.6834267,13.3200955 C15.122757,13.0431858 16.1425715,12.2397272 16.2000668,11.9730903 C16.384967,11.1156072 15.7817511,10.8779297 15.3694426,10.3391927 C15.775744,9.98296441 16.6326574,9.41053232 16.6812937,9.05447049 C16.7393063,8.62976537 15.6663571,7.89615885 15.3694426,7.61328125 C15.6663571,7.27799479 16.1457817,6.63265928 16.2000668,6.23524306 C16.2543519,5.83782683 15.7961683,5.55488051 15.3694426,5.48372396 C14.9427169,5.4125674 14.0426282,5.48372396 12.8631528,5.76931424 C12.0768358,5.95970775 10.7998989,6.33288634 9.03234221,6.88884999 Z", id "Shape" ] [], Svg.path [ d "M2.68421053,13.944553 L1.30636275,13.7628581 C0.713441441,13.6611328 0.431804456,13.3206975 0.28594007,12.7623698 C0.140075684,12.2040421 2.4416657e-17,11.6365017 0,10.5636936 C0,9.49088542 0.164978027,8.73611111 0.28594007,8.21929253 C0.406902112,7.70247396 0.61660606,7.33691406 1.1561184,7.23855252 L2.47215833,7.11111111 C2.27545166,8.30470417 2.17709832,9.45556499 2.17709832,10.5636936 C2.17709832,11.6718222 2.34613573,12.7987753 2.68421053,13.944553 Z", id "Path" ] [] ] ] ]


thumbsSmall : Html msg
thumbsSmall =
    iconView <|
        svg [ width "15px", height "15px", viewBox "0 0 15 15", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "thumbs-up-copy-4", transform "translate(0.500000, 1.000000)", stroke "#8A98A5" ] [ Svg.path [ d "M7.43839947,5.59719062 L7.9401213,2.20025635 C7.9401213,1.30279945 7.50638441,0.372043186 6.57599198,0.372043186 C6.14529687,2.2703327 5.73885841,3.60945307 5.3566766,4.3894043 C5.06962719,4.97521068 4.4648566,5.44984493 3.54236482,5.81330702 C3.41827865,6.77811362 3.37231596,7.72582458 3.40447677,8.65643989 C3.43663757,9.5870552 3.57485543,10.5115502 3.81913035,11.4299249 C5.62888201,12.1043617 7.00254567,12.4958299 7.9401213,12.6043294 C9.19028834,12.7490031 9.70091488,12.7490031 10.9195107,12.7480333 C12.1381065,12.7470635 12.4562474,12.1857834 12.4562474,11.6743978 C12.4562474,11.1630122 12.2953331,11.1949734 12.0922338,10.8225776 C12.4540351,10.5975884 13.2938825,9.94477835 13.3412315,9.72813585 C13.4935022,9.03143088 12.9967362,8.83831787 12.657188,8.40059408 C12.9917892,8.11115858 13.6974826,7.64605751 13.737536,7.35675727 C13.7853111,7.01168436 12.9017058,6.41562907 12.657188,6.18579102 C12.9017058,5.91337077 13.2965261,5.38903567 13.3412315,5.06613498 C13.3859369,4.7432343 13.0086092,4.51334042 12.657188,4.45552572 C12.3057669,4.39771101 11.5645174,4.45552572 10.5931846,4.68756782 C9.94562945,4.84226255 8.8940344,5.14547015 7.43839947,5.59719062 Z", id "Shape" ] [], Svg.path [ d "M2.21052632,11.3299493 L1.07582815,11.1823222 C0.58754001,11.0996704 0.35560367,10.8230667 0.235480058,10.3694255 C0.115356445,9.91578421 2.01078352e-17,9.45465766 0,8.58300103 C0,7.7113444 0.135864258,7.09809028 0.235480058,6.67817518 C0.335095857,6.25826009 0.507793226,5.96124268 0.952097505,5.88132392 L2.0358951,5.77777778 C1.87390137,6.74757214 1.7929045,7.68264655 1.7929045,8.58300103 C1.7929045,9.48335551 1.93211177,10.3990049 2.21052632,11.3299493 Z", id "Path" ] [] ] ] ]


undismissed : Html msg
undismissed =
    iconView <|
        svg [ width "22px", height "22px", viewBox "0 0 22 22", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "check-circle", transform "translate(1.000000, 0.000000)", strokeWidth "2" ] [ Svg.path [ d "M20,10.08 L20,11 C19.9974678,15.4286859 17.082294,19.328213 12.8353524,20.583901 C8.58841086,21.839589 4.02139355,20.1523121 1.61095509,16.4370663 C-0.799483376,12.7218205 -0.479136554,7.86363898 2.39827419,4.49707214 C5.27568494,1.13050531 10.0247126,0.0575252842 14.07,1.86", id "Shape", stroke "#11E72B" ] [], polyline [ id "Shape", stroke "#E2E6E8", points "20 3 10 13.01 7 10.01" ] [] ] ] ]


unlock : Html msg
unlock =
    iconView <|
        svg [ width "16px", height "20px", viewBox "0 0 16 20", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "unlock", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ rect [ id "Rectangle-path", x "0", y "8.12030075", width "14", height "8.93233083", rx "2" ] [], Svg.path [ d "M3.11110911,8.12030075 L3.11111111,4.87218045 C3.10910319,2.7862656 4.62135513,1.03813725 6.60916974,0.828505399 C8.59698434,0.61887355 10.4135331,2.01595173 10.8111111,4.06015038", id "Shape" ] [] ] ] ]


ex : Html msg
ex =
    iconView <|
        svg [ width "14px", height "14px", viewBox "0 0 14 14", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "x", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M12,0 L0,12", id "Path" ] [], Svg.path [ d "M0,0 L12,12", id "Path" ] [] ] ] ]


zapWhite : Html msg
zapWhite =
    iconView <|
        svg [ width "18px", height "20px", viewBox "0 0 18 20", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "zap", transform "translate(1.000000, 1.000000)", fill "#FFFFFF", stroke "#FFFFFF", strokeWidth "2" ] [ polygon [ id "Path", points "8.88888889 0 0 10.8 8 10.8 7.11111111 18 16 7.2 8 7.2" ] [] ] ] ]
