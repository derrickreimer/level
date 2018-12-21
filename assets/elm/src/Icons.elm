module Icons exposing (Toggle(..), arrowLeft, arrowRight, arrowUpRight, atSign, bookmark, check, checkSquare, closed, closedAvatar, comment, edit, file, filter, heart, image, inbox, inboxWhite, lock, logOut, logo, menu, more, open, refresh, reply, revokeMember, search, square, thumbs, thumbsSmall, undismissed, unlock)

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


arrowLeft : Toggle -> Html msg
arrowLeft toggle =
    let
        color =
            case toggle of
                On ->
                    "#8a98a5"

                Off ->
                    "#e2e6e8"
    in
    iconView <|
        svg [ width "16px", height "14px", viewBox "0 0 16 14", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "arrow-left", transform "translate(1.000000, 1.000000)", stroke color, strokeWidth "2" ] [ Svg.path [ d "M14,6 L0,6", id "Shape" ] [], polyline [ id "Shape", points "6 12 0 6 6 0" ] [] ] ] ]


arrowRight : Toggle -> Html msg
arrowRight toggle =
    let
        color =
            case toggle of
                On ->
                    "#8a98a5"

                Off ->
                    "#e2e6e8"
    in
    iconView <|
        svg [ width "16px", height "14px", viewBox "0 0 16 14", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "arrow-right", transform "translate(8.000000, 7.000000) scale(-1, 1) translate(-8.000000, -7.000000) translate(1.000000, 1.000000)", stroke color, strokeWidth "2" ] [ Svg.path [ d "M14,6 L0,6", id "Shape" ] [], polyline [ id "Shape", points "6 12 0 6 6 0" ] [] ] ] ]


arrowUpRight : Html msg
arrowUpRight =
    iconView <|
        svg [ width "10px", height "10px", viewBox "0 0 10 10", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "arrow-up-right", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M0,8 L8,0", id "Shape" ] [], polyline [ id "Shape", points "0 0 8 0 8 8" ] [] ] ] ]


atSign : Html msg
atSign =
    iconView <|
        svg [ width "18px", height "18px", viewBox "0 0 18 18", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "at-sign", transform "translate(1.000000, 1.000000)", stroke "#DF9700", strokeWidth "2" ] [ circle [ id "Oval", cx "8.38095238", cy "7.61904762", r "3.04761905" ] [], Svg.path [ d "M11.4285714,4.57142857 L11.4285714,8.38095238 C11.4285714,9.64331752 12.4519206,10.6666667 13.7142857,10.6666667 C14.9766509,10.6666667 16,9.64331752 16,8.38095238 L16,7.61904762 C15.999777,4.07840349 13.5604834,1.00450615 10.1124865,0.19984573 C6.6644896,-0.604814687 3.11655739,1.07184135 1.54914737,4.24664634 C-0.0182626518,7.42145134 0.807962392,11.2576409 3.54333577,13.5057275 C6.27870914,15.7538142 10.2022849,15.8212831 13.0133333,13.6685714", id "Shape" ] [] ] ] ]


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


closedAvatar : Html msg
closedAvatar =
    iconView <|
        svg [ width "36px", height "36px", viewBox "0 0 36 36", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd" ] [ g [ id "closed-avatar-2" ] [ circle [ id "Oval-2", fill "#8A98A5", cx "18", cy "18", r "18" ] [], g [ id "check", transform "translate(10.000000, 13.000000)", stroke "#FFFFFF", strokeLinecap "round", strokeLinejoin "round", strokeWidth "2" ] [ polyline [ id "Shape", points "16 0 5 11 0 6" ] [] ] ] ] ]


edit : Html msg
edit =
    iconView <|
        svg [ width "17px", height "17px", viewBox "0 0 17 17", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "edit", transform "translate(1.000000, 1.000000)", stroke "#c6ced2", strokeWidth "2" ] [ Svg.path [ d "M14.4,8.128 L14.4,13.4 C14.4,14.2836556 13.6836556,15 12.8,15 L1.6,15 C0.7163444,15 0,14.2836556 0,13.4 L0,2.2 C-1.77635684e-16,1.3163444 0.7163444,0.6 1.6,0.6 L5.872,0.6", id "Path" ] [], polygon [ id "Path", fill "#c6ced2", points "14 2.98431373 6.78431373 10.2 4.8 10.2 4.8 8.21568627 12.0156863 1" ] [] ] ] ]


file : Color -> Html msg
file strokeColor =
    iconView <|
        svg [ width "14px", height "17px", viewBox "0 0 14 17", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "file", transform "translate(1.000000, 1.000000)", stroke (Color.toHex strokeColor), strokeWidth "2" ] [ Svg.path [ d "M6.75,0 L1.5,0 C0.671572875,0 0,0.671572875 0,1.5 L0,13.5 C0,14.3284271 0.671572875,15 1.5,15 L10.5,15 C11.3284271,15 12,14.3284271 12,13.5 L12,5.25 L6.75,0 Z", id "Shape" ] [], polyline [ id "Shape", points "6.75 0 6.75 5.25 12 5.25" ] [] ] ] ]


filter : Html msg
filter =
    iconView <|
        svg [ width "19px", height "17px", viewBox "0 0 19 17", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "filter", transform "translate(1.000000, 1.000000)", stroke "#FFFFFF", strokeWidth "2" ] [ polygon [ id "Shape", points "17 0 0 0 6.8 7.88333333 6.8 13.3333333 10.2 15 10.2 7.88333333" ] [] ] ] ]


image : Color -> Html msg
image strokeColor =
    iconView <|
        svg [ width "17px", height "17px", viewBox "0 0 17 17", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "image", transform "translate(1.000000, 1.000000)", stroke (Color.toHex strokeColor), strokeWidth "2" ] [ rect [ id "Rectangle-path", x "0", y "0", width "15", height "15", rx "2" ] [], circle [ id "Oval", cx "4.58333333", cy "4.58333333", r "1.25" ] [], polyline [ id "Shape", points "15 10 10.8333333 5.83333333 1.66666667 15" ] [] ] ] ]


inboxWhite : Html msg
inboxWhite =
    iconView <|
        svg [ width "17px", height "14px", viewBox "0 0 17 14", version "1.1" ] [ desc [] [ text "Created with Sketch." ], defs [] [], g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "inbox", transform "translate(1.000000, 1.000000)", stroke "#fff", strokeWidth "2" ] [ Svg.path [ d "M15,6 L12.4125,0.8325 C12.1592025,0.322756741 11.639208,0.000302043969 11.07,0 L3.93,0 C3.36079202,0.000302043969 2.84079751,0.322756741 2.5875,0.8325 L0,6", id "Shape" ] [], Svg.path [ d "M10.5,6 L15,6 L15,10.5 C15,11.3284271 14.3284271,12 13.5,12 L1.5,12 C0.671572875,12 0,11.3284271 0,10.5 L0,6 L4.5,6 L6,8.25 L9,8.25 L10.5,6 Z", id "Combined-Shape", fill "#fff" ] [] ] ] ]


inbox : Toggle -> Html msg
inbox toggle =
    let
        color =
            case toggle of
                On ->
                    "#38C172"

                Off ->
                    "#c6ced2"
    in
    iconView <|
        svg [ width "17px", height "14px", viewBox "0 0 17 14", version "1.1" ] [ desc [] [ text "Created with Sketch." ], defs [] [], g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "inbox", transform "translate(1.000000, 1.000000)", stroke color, strokeWidth "2" ] [ Svg.path [ d "M15,6 L12.4125,0.8325 C12.1592025,0.322756741 11.639208,0.000302043969 11.07,0 L3.93,0 C3.36079202,0.000302043969 2.84079751,0.322756741 2.5875,0.8325 L0,6", id "Shape" ] [], Svg.path [ d "M10.5,6 L15,6 L15,10.5 C15,11.3284271 14.3284271,12 13.5,12 L1.5,12 C0.671572875,12 0,11.3284271 0,10.5 L0,6 L4.5,6 L6,8.25 L9,8.25 L10.5,6 Z", id "Combined-Shape", fill color ] [] ] ] ]


logOut : Html msg
logOut =
    iconView <|
        svg [ width "20px", height "20px", viewBox "0 0 20 20", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "log-out", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M6,18 L2,18 C0.8954305,18 0,17.1045695 0,16 L0,2 C0,0.8954305 0.8954305,0 2,0 L6,0", id "Shape" ] [], polyline [ id "Shape", points "13 14 18 9 13 4" ] [], Svg.path [ d "M18,9 L6,9", id "Shape" ] [] ] ] ]


menu : Html msg
menu =
    iconView <|
        svg [ width "16px", height "12px", viewBox "0 0 16 12", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "menu", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M0,5 L14,5", id "Shape" ] [], Svg.path [ d "M0,0 L14,0", id "Shape" ] [], Svg.path [ d "M0,10 L14,10", id "Shape" ] [] ] ] ]


more : Html msg
more =
    iconView <|
        svg [ width "18px", height "4px", viewBox "0 0 18 4", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "more-horizontal", transform "translate(1.000000, 1.000000)", stroke "#C6CED2", strokeWidth "2" ] [ circle [ id "Oval", cx "8", cy "1", r "1" ] [], circle [ id "Oval", cx "15", cy "1", r "1" ] [], circle [ id "Oval", cx "1", cy "1", r "1" ] [] ] ] ]


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


comment : Html msg
comment =
    iconView <|
        svg [ width "16px", height "16px", viewBox "0 0 16 16", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "message-square-copy", transform "translate(1.000000, 1.000000)", fill "#c6ced2", stroke "#c6ced2", strokeWidth "2" ] [ Svg.path [ d "M14,9.33333333 C14,10.1924429 13.3035541,10.8888889 12.4444444,10.8888889 L3.11111111,10.8888889 L0,14 L0,1.55555556 C0,0.696445945 0.696445945,0 1.55555556,0 L12.4444444,0 C13.3035541,0 14,0.696445945 14,1.55555556 L14,9.33333333 Z", id "Shape" ] [] ] ] ]


heart : Html msg
heart =
    iconView <|
        svg [ width "20px", height "17px", viewBox "0 0 20 17", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "heart", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ Svg.path [ d "M15.7837833,1.2894605 C14.939809,0.463853671 13.7948962,-7.10542736e-16 12.601056,0 C11.4072158,3.55271368e-16 10.2623031,0.463853671 9.41832875,1.2894605 L8.55105603,2.1374605 L7.6837833,1.2894605 C5.92601156,-0.429249601 3.07610052,-0.42924958 1.3183288,1.28946054 C-0.439442915,3.00817067 -0.439442937,5.79475035 1.31832875,7.5134605 L2.18560148,8.3614605 L8.55105603,14.5854605 L14.9165106,8.3614605 L15.7837833,7.5134605 C16.6281539,6.68824114 17.1025497,5.56877092 17.1025497,4.4014605 C17.1025497,3.23415007 16.6281539,2.11467986 15.7837833,1.2894605 Z", id "Shape" ] [] ] ] ]


lock : Html msg
lock =
    iconView <|
        svg [ width "16px", height "18px", viewBox "0 0 16 18", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "lock", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ rect [ id "Rectangle-path", fill "#8A98A5", x "0", y "7.2", width "14", height "8.8", rx "2" ] [], Svg.path [ d "M3.11111111,7.2 L3.11111111,4 C3.11111111,1.790861 4.85222597,1.24344979e-15 7,8.8817842e-16 C9.14777403,1.77635684e-16 10.8888889,1.790861 10.8888889,4 L10.8888889,7.2", id "Shape" ] [] ] ] ]


logo : Html msg
logo =
    svg [ width "99px", height "20px", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd" ] [ g [ transform "translate(-661.000000, -131.000000)" ] [ g [ transform "translate(661.000000, 131.000000)" ] [ Svg.path [ d "M7,1 L23,1 C24.1045695,1 25,1.8954305 25,3 C25,4.1045695 24.1045695,5 23,5 L7,5 C5.8954305,5 5,4.1045695 5,3 C5,1.8954305 5.8954305,1 7,1 Z M12,8 L28,8 C29.1045695,8 30,8.8954305 30,10 C30,11.1045695 29.1045695,12 28,12 L12,12 C10.8954305,12 10,11.1045695 10,10 C10,8.8954305 10.8954305,8 12,8 Z M2,15 L18,15 C19.1045695,15 20,15.8954305 20,17 C20,18.1045695 19.1045695,19 18,19 L2,19 C0.8954305,19 1.3527075e-16,18.1045695 0,17 C-1.3527075e-16,15.8954305 0.8954305,15 2,15 Z", fill "#12C1D5" ] [], Svg.path [ d "M38,17.8074866 L38,2.03208556 C38,0.909090909 38.9144621,0 40.0440917,0 C41.1737213,0 42.0881834,0.909090909 42.0881834,2.03208556 L42.0881834,17.8074866 C42.0881834,18.9304813 41.1737213,19.8395722 40.0440917,19.8395722 C38.9144621,19.8395722 38,18.9304813 38,17.8074866 Z M57.7685185,18.2620321 C56.5044092,19.3315508 54.8637566,20 52.765873,20 C48.4356261,20 45.2350088,16.9786096 45.2350088,12.5935829 L45.2350088,12.540107 C45.2350088,8.44919786 48.1666667,5.0802139 52.3624339,5.0802139 C57.1768078,5.0802139 59.3015873,9.01069519 59.3015873,11.9786096 C59.3015873,13.1550802 58.4678131,13.9304813 57.3919753,13.9304813 L49.2962963,13.9304813 C49.6997354,15.7754011 50.9907407,16.7379679 52.8196649,16.7379679 C53.9492945,16.7379679 54.8906526,16.3903743 55.7244268,15.7754011 C56.0202822,15.5614973 56.2892416,15.4545455 56.7195767,15.4545455 C57.6340388,15.4545455 58.3064374,16.1497326 58.3064374,17.0588235 C58.3064374,17.5935829 58.0643739,17.9946524 57.7685185,18.2620321 Z M49.2425044,11.3903743 L55.4016755,11.3903743 C55.159612,9.57219251 54.0837743,8.34224599 52.3624339,8.34224599 C50.6679894,8.34224599 49.5652557,9.54545455 49.2425044,11.3903743 Z M70.9206349,18.2085561 C70.4634039,19.2513369 69.7103175,19.973262 68.6075838,19.973262 L68.3924162,19.973262 C67.2896825,19.973262 66.5365961,19.2780749 66.0793651,18.2085561 L61.6684303,8.07486631 C61.5608466,7.80748663 61.4532628,7.45989305 61.4532628,7.0855615 C61.4532628,6.12299465 62.3408289,5.18716578 63.4435626,5.18716578 C64.5462963,5.18716578 65.1380071,5.80213904 65.4338624,6.63101604 L68.5268959,14.9465241 L71.6737213,6.57754011 C71.9426808,5.88235294 72.5074956,5.18716578 73.5833333,5.18716578 C74.6591711,5.18716578 75.5467372,6.01604278 75.5467372,7.11229947 C75.5467372,7.45989305 75.4122575,7.88770053 75.3315697,8.07486631 L70.9206349,18.2085561 Z M90.0705467,18.2620321 C88.8064374,19.3315508 87.1657848,20 85.0679012,20 C80.7376543,20 77.537037,16.9786096 77.537037,12.5935829 L77.537037,12.540107 C77.537037,8.44919786 80.4686949,5.0802139 84.6644621,5.0802139 C89.478836,5.0802139 91.6036155,9.01069519 91.6036155,11.9786096 C91.6036155,13.1550802 90.7698413,13.9304813 89.6940035,13.9304813 L81.5983245,13.9304813 C82.0017637,15.7754011 83.292769,16.7379679 85.1216931,16.7379679 C86.2513228,16.7379679 87.1926808,16.3903743 88.026455,15.7754011 C88.3223104,15.5614973 88.5912698,15.4545455 89.0216049,15.4545455 C89.936067,15.4545455 90.6084656,16.1497326 90.6084656,17.0588235 C90.6084656,17.5935829 90.3664021,17.9946524 90.0705467,18.2620321 Z M81.5445326,11.3903743 L87.7037037,11.3903743 C87.4616402,9.57219251 86.3858025,8.34224599 84.6644621,8.34224599 C82.9700176,8.34224599 81.867284,9.54545455 81.5445326,11.3903743 Z M94.9118166,17.8074866 L94.9118166,2.03208556 C94.9118166,0.909090909 95.8262787,0 96.9559083,0 C98.0855379,0 99,0.909090909 99,2.03208556 L99,17.8074866 C99,18.9304813 98.0855379,19.8395722 96.9559083,19.8395722 C95.8262787,19.8395722 94.9118166,18.9304813 94.9118166,17.8074866 Z", id "level", fill "#22384C" ] [] ] ] ] ]


reply : Html msg
reply =
    iconView <|
        svg [ width "14px", height "14px", viewBox "0 0 14 14", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "corner-up-left", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ polyline [ id "Shape", points "3.75 7.5 0 3.75 3.75 0" ] [], Svg.path [ d "M11.8181818,12 L11.8181818,6.90909091 C11.8181818,5.30244436 10.5157375,4 8.90909091,4 L0.181818182,4", id "Shape" ] [] ] ] ]


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
        svg [ width "16px", height "16px", viewBox "0 0 16 16", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "search", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ circle [ id "Oval", cx "6.22222222", cy "6.22222222", r "6.22222222" ] [], Svg.path [ d "M14,14 L10.6166667,10.6166667", id "Shape" ] [] ] ] ]


square : Html msg
square =
    iconView <|
        svg [ width "20px", height "20px", viewBox "0 0 20 20", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "square", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ rect [ id "Rectangle-path", x "0", y "0", width "18", height "18", rx "2" ] [] ] ] ]


thumbs : Toggle -> Html msg
thumbs toggle =
    let
        color =
            case toggle of
                On ->
                    "#38C172"

                Off ->
                    "#c6ced2"
    in
    iconView <|
        svg [ width "19px", height "20px", viewBox "0 0 19 20", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "thumbs-up", transform "translate(1.000000, 1.000000)", fill color, stroke color, strokeWidth "2" ] [ Svg.path [ d "M8.0949707,7.74995624 L8.77587891,3.04650879 C8.77587891,1.80387616 8.18723598,0.515136719 6.92456055,0.515136719 C6.34004575,3.14353758 5.78845069,4.99770425 5.26977539,6.07763672 C4.88020833,6.88875326 4.39376994,7.4461931 3.81046021,7.74995624 L3.81046021,16.1645508 C5.84831527,16.8727191 7.50345483,17.3019184 8.77587891,17.4521484 C10.4725342,17.6524658 11.1655273,17.6524658 12.8193359,17.651123 C14.4731445,17.6497803 14.9049072,16.8726232 14.9049072,16.1645508 C14.9049072,15.4564784 13.684082,15.2393799 13.4084473,14.7237549 C13.8994634,14.4122314 16.0416976,13.7696931 16.105957,13.4697266 C16.3126102,12.5050581 14.4718018,12.2149658 14.0109863,11.6088867 C14.4650879,11.2081299 16.5291379,10.4790608 16.5834961,10.0784912 C16.6483337,9.60069795 14.7903911,9.3182373 14.4585455,9 C14.7903911,8.62280273 16.0452854,7.54487158 16.105957,7.09777832 C16.1666286,6.65068507 15.654541,6.24924058 15.1776123,6.16918945 C14.7006836,6.08913833 13.6947021,6.16918945 12.3764648,6.49047852 C11.49764,6.70467122 10.0704753,7.12449713 8.0949707,7.74995624 Z", id "Shape" ] [], Svg.path [ d "M0.810460209,16 L0.324184083,16 C0.145142158,16 0,15.4010268 0,14.662156 L0,9.08780024 C-3.59916634e-17,8.3489294 0.145142158,7.74995624 0.324184083,7.74995624 L0.810460209,7.74995624 L0.810460209,16 Z", id "Path" ] [] ] ] ]


thumbsSmall : Toggle -> Html msg
thumbsSmall toggle =
    let
        color =
            case toggle of
                On ->
                    "#38C172"

                Off ->
                    "#c6ced2"
    in
    iconView <|
        svg [ width "14px", height "14px", viewBox "0 0 14 14", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "thumbs-up-copy", transform "translate(1.000000, 1.000000)", fill color, stroke color, strokeWidth "2" ] [ Svg.path [ d "M6.23792222,5.16663749 L6.67850988,2.03100586 C6.67850988,1.20258411 6.29762328,0.343424479 5.480598,0.343424479 C5.10238254,2.09569172 4.7454681,3.33180283 4.40985466,4.05175781 C4.15778186,4.59250217 3.84302761,4.96412873 3.4655919,5.16663749 L3.4655919,10.7763672 C4.784204,11.2484794 5.85517666,11.5346122 6.67850988,11.6347656 C7.77634565,11.7683105 8.22475299,11.7683105 9.29486443,11.7674154 C10.3649759,11.7665202 10.6443517,11.2484154 10.6443517,10.7763672 C10.6443517,10.3043189 9.85440602,10.1595866 9.67605411,9.81583659 C9.99377045,9.6081543 11.379922,9.1797954 11.4215016,8.97981771 C11.5552184,8.33670542 10.364107,8.14331055 10.0659323,7.73925781 C10.3597628,7.47208659 11.6953245,6.98604052 11.7304975,6.71899414 C11.7724512,6.4004653 10.570253,6.2121582 10.3555294,6 C10.570253,5.74853516 11.3822435,5.02991438 11.4215016,4.73185221 C11.4607597,4.43379004 11.1294089,4.16616039 10.820808,4.11279297 C10.512207,4.05942555 9.86127786,4.11279297 9.00830078,4.32698568 C8.43964939,4.46978082 7.51618987,4.74966475 6.23792222,5.16663749 Z", id "Shape" ] [], Svg.path [ d "M0.524415429,10.6666667 L0.209766172,10.6666667 C0.093915514,10.6666667 0,10.2673512 0,9.77477067 L0,6.05853349 C-2.32887234e-17,5.56595293 0.093915514,5.16663749 0.209766172,5.16663749 L0.524415429,5.16663749 L0.524415429,10.6666667 Z", id "Path" ] [] ] ] ]


undismissed : Html msg
undismissed =
    iconView <|
        svg [ width "22px", height "22px", viewBox "0 0 22 22", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "check-circle", transform "translate(1.000000, 0.000000)", strokeWidth "2" ] [ Svg.path [ d "M20,10.08 L20,11 C19.9974678,15.4286859 17.082294,19.328213 12.8353524,20.583901 C8.58841086,21.839589 4.02139355,20.1523121 1.61095509,16.4370663 C-0.799483376,12.7218205 -0.479136554,7.86363898 2.39827419,4.49707214 C5.27568494,1.13050531 10.0247126,0.0575252842 14.07,1.86", id "Shape", stroke "#11E72B" ] [], polyline [ id "Shape", stroke "#E2E6E8", points "20 3 10 13.01 7 10.01" ] [] ] ] ]


unlock : Html msg
unlock =
    iconView <|
        svg [ width "16px", height "20px", viewBox "0 0 16 20", version "1.1" ] [ g [ stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "unlock", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ rect [ id "Rectangle-path", x "0", y "8.12030075", width "14", height "8.93233083", rx "2" ] [], Svg.path [ d "M3.11110911,8.12030075 L3.11111111,4.87218045 C3.10910319,2.7862656 4.62135513,1.03813725 6.60916974,0.828505399 C8.59698434,0.61887355 10.4135331,2.01595173 10.8111111,4.06015038", id "Shape" ] [] ] ] ]
