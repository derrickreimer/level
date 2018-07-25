module Icons
    exposing
        ( Toggle(..)
        , bookmark
        , heart
        , sync
        , comment
        , arrowLeft
        )

import Html exposing (Html)
import ViewHelpers exposing (injectHtml)


type Toggle
    = On
    | Off


toHtml : String -> Html msg
toHtml =
    injectHtml


bookmark : Toggle -> Html msg
bookmark style =
    case style of
        Off ->
            toHtml
                """
                <svg width="16px" height="20px" viewBox="0 0 16 20" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
                    <!-- Generator: Sketch 50.2 (55047) - http://www.bohemiancoding.com/sketch -->
                    <desc>Created with Sketch.</desc>
                    <defs></defs>
                    <g id="Page-1" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round">
                        <g id="bookmark" transform="translate(1.000000, 1.000000)" fill="#E2E6E8" stroke="#E2E6E8" stroke-width="2">
                            <path d="M14,18 L7,13 L0,18 L0,2 C0,0.8954305 0.8954305,0 2,0 L12,0 C13.1045695,0 14,0.8954305 14,2 L14,18 Z" id="Shape"></path>
                        </g>
                    </g>
                </svg>
                """

        On ->
            toHtml
                """
                <svg width="16px" height="20px" viewBox="0 0 16 20" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
                    <!-- Generator: Sketch 50.2 (55047) - http://www.bohemiancoding.com/sketch -->
                    <desc>Created with Sketch.</desc>
                    <defs></defs>
                    <g id="Page-1" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round">
                        <g id="bookmark-copy" transform="translate(1.000000, 1.000000)" fill="#13C1D5" stroke="#13C1D5" stroke-width="2">
                            <path d="M14,18 L7,13 L0,18 L0,2 C0,0.8954305 0.8954305,0 2,0 L12,0 C13.1045695,0 14,0.8954305 14,2 L14,18 Z" id="Shape"></path>
                        </g>
                    </g>
                </svg>
                """


heart : Html msg
heart =
    toHtml
        """
        <svg width="20px" height="17px" viewBox="0 0 20 17" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <!-- Generator: Sketch 50.2 (55047) - http://www.bohemiancoding.com/sketch -->
            <desc>Created with Sketch.</desc>
            <defs></defs>
            <g id="Page-1" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round">
                <g id="heart" transform="translate(1.000000, 1.000000)" stroke="#8A98A5" stroke-width="2">
                    <path d="M15.7837833,1.2894605 C14.939809,0.463853671 13.7948962,-7.10542736e-16 12.601056,0 C11.4072158,3.55271368e-16 10.2623031,0.463853671 9.41832875,1.2894605 L8.55105603,2.1374605 L7.6837833,1.2894605 C5.92601156,-0.429249601 3.07610052,-0.42924958 1.3183288,1.28946054 C-0.439442915,3.00817067 -0.439442937,5.79475035 1.31832875,7.5134605 L2.18560148,8.3614605 L8.55105603,14.5854605 L14.9165106,8.3614605 L15.7837833,7.5134605 C16.6281539,6.68824114 17.1025497,5.56877092 17.1025497,4.4014605 C17.1025497,3.23415007 16.6281539,2.11467986 15.7837833,1.2894605 Z" id="Shape"></path>
                </g>
            </g>
        </svg>
        """


sync : Html msg
sync =
    toHtml
        """
        <svg width="20px" height="17px" viewBox="0 0 20 17" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <!-- Generator: Sketch 50.2 (55047) - http://www.bohemiancoding.com/sketch -->
            <desc>Created with Sketch.</desc>
            <defs></defs>
            <g id="Page-1" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round">
                <g id="refresh-cw" transform="translate(1.000000, 1.000000)" stroke="#8A98A5" stroke-width="2">
                    <polyline id="Shape" points="17.6 0.799999979 17.6 5.59999985 12.8 5.59999985"></polyline>
                    <polyline id="Shape" points="0 13.5999996 0 8.79999977 4.8 8.79999977"></polyline>
                    <path d="M2.008,4.79999987 C2.83270531,2.46944926 4.79541373,0.724974577 7.20662937,0.179406607 C9.61784502,-0.366161362 12.1403527,0.363476577 13.888,2.11199994 L17.6,5.59999985 M0,8.79999977 L3.712,12.2879997 C5.45964733,14.036523 7.98215498,14.766161 10.3933706,14.220593 C12.8045863,13.675025 14.7672947,11.9305504 15.592,9.59999975" id="Shape"></path>
                </g>
            </g>
        </svg>
        """


comment : Html msg
comment =
    toHtml
        """
        <svg width="16px" height="16px" viewBox="0 0 16 16" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <!-- Generator: Sketch 50.2 (55047) - http://www.bohemiancoding.com/sketch -->
            <desc>Created with Sketch.</desc>
            <defs></defs>
            <g id="Page-1" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round">
                <g id="message-square" transform="translate(1.000000, 1.000000)" stroke="#8A98A5" stroke-width="2">
                    <path d="M14,9.33333333 C14,10.1924429 13.3035541,10.8888889 12.4444444,10.8888889 L3.11111111,10.8888889 L0,14 L0,1.55555556 C0,0.696445945 0.696445945,0 1.55555556,0 L12.4444444,0 C13.3035541,0 14,0.696445945 14,1.55555556 L14,9.33333333 Z" id="Shape"></path>
                </g>
            </g>
        </svg>
        """


arrowLeft : Html msg
arrowLeft =
    toHtml
        """
        <svg width="16px" height="14px" viewBox="0 0 16 14" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <!-- Generator: Sketch 50.2 (55047) - http://www.bohemiancoding.com/sketch -->
            <desc>Created with Sketch.</desc>
            <defs></defs>
            <g id="Page-1" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round">
                <g id="arrow-left" transform="translate(1.000000, 1.000000)" stroke="#8A98A5" stroke-width="2">
                    <path d="M14,6 L0,6" id="Shape"></path>
                    <polyline id="Shape" points="6 12 0 6 6 0"></polyline>
                </g>
            </g>
        </svg>
        """
