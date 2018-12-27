module Vendor.SelectList exposing
    ( SelectList, fromLists, singleton
    , toList, before, selected, after
    , map, mapBy, Position(..), select, append, prepend
    )

{-| A `SelectList` is a nonempty list which always has exactly one element selected.

It is an example of a list [zipper](https://en.wikipedia.org/wiki/Zipper_(data_structure)).

@docs SelectList, fromLists, singleton


## Reading

@docs toList, before, selected, after


## Transforming

@docs map, mapBy, Position, select, append, prepend

-}


{-| A nonempty list which always has exactly one element selected.

Create one using [`fromLists`](#fromLists).

-}
type SelectList a
    = SelectList (List a) a (List a)


{-| Return the elements before the selected element.

    import SelectList

    SelectList.fromLists [ 1, 2 ] 3 [ 4, 5, 6 ]
        |> SelectList.before

    == [ 1, 2 ]

-}
before : SelectList a -> List a
before (SelectList beforeSel _ _) =
    beforeSel


{-| Return the elements after the selected element.

    import SelectList

    SelectList.fromLists [ 1, 2 ] 3 [ 4, 5, 6 ]
        |> SelectList.after

    == [ 3, 4, 5 ]

-}
after : SelectList a -> List a
after (SelectList _ _ afterSel) =
    afterSel


{-| Return the selected element.

    import SelectList

    SelectList.fromLists [ 1, 2 ] 3 [ 4, 5, 6 ]
        |> SelectList.selected

    == 3

-}
selected : SelectList a -> a
selected (SelectList _ sel _) =
    sel


{-| A `SelectList` containing exactly one element.

    import SelectList

    SelectList.singleton "foo"

    == SelectList.fromLists [] "foo" []

-}
singleton : a -> SelectList a
singleton sel =
    SelectList [] sel []


{-| Transform each element of the `SelectList`. The transform
function receives a `Position` which is `Selected` if it was passed
the SelectList's selected element, `BeforeSelected` if it was passed an element
before the selected element, and `AfterSelected` otherwise.

    import SelectList exposing (Position(..))

    doubleOrNegate position num =
        if position == Selected then
            num * -1
        else
            num * 2


    SelectList.fromLists [ 1, 2 ] 3 [ 4, 5, 6 ]
        |> SelectList.mapBy doubleOrNegate

    == SelectList.fromLists [ 2, 4 ] -3 [ 8, 10, 12 ]

-}
mapBy : (Position -> a -> b) -> SelectList a -> SelectList b
mapBy transform (SelectList beforeSel sel afterSel) =
    SelectList
        (List.map (transform BeforeSelected) beforeSel)
        (transform Selected sel)
        (List.map (transform AfterSelected) afterSel)


{-| Used with [`mapBy`](#mapBy).
-}
type Position
    = BeforeSelected
    | Selected
    | AfterSelected


{-| Transform each element of the `SelectList`.

    import SelectList

    SelectList.fromLists [ 1, 2 ] 3 [ 4, 5, 6 ]
        |> SelectList.map (\num -> num * 2)

    == SelectList.fromLists [ 2, 4 ] 6 [ 8, 10, 12 ]

-}
map : (a -> b) -> SelectList a -> SelectList b
map transform (SelectList beforeSel sel afterSel) =
    SelectList
        (List.map transform beforeSel)
        (transform sel)
        (List.map transform afterSel)


{-| Returns a `SelectList`.

    import SelectList

    SelectList.fromLists [ 1, 2 ] 3 [ 4, 5, 6 ]
        |> SelectList.selected

    == 3

-}
fromLists : List a -> a -> List a -> SelectList a
fromLists =
    SelectList


{-| Change the selected element to the first one which passes a
predicate function. If no elements pass, the `SelectList` is unchanged.

    import SelectList

    isEven num =
        num % 2 == 0


    SelectList.fromLists [ 1, 2 ] 3 [ 4, 5, 6 ]
        |> SelectList.select isEven

    == SelectList.fromLists [ 1 ] 2 [ 3, 4, 5, 6 ]

-}
select : (a -> Bool) -> SelectList a -> SelectList a
select isSelectable ((SelectList beforeSel sel afterSel) as original) =
    case selectHelp isSelectable beforeSel sel afterSel of
        Nothing ->
            original

        Just ( newBefore, newSel, newAfter ) ->
            SelectList newBefore newSel newAfter


selectHelp : (a -> Bool) -> List a -> a -> List a -> Maybe ( List a, a, List a )
selectHelp isSelectable beforeList selectedElem afterList =
    case ( beforeList, afterList ) of
        ( [], [] ) ->
            Nothing

        ( [], first :: rest ) ->
            if isSelectable selectedElem then
                Just ( beforeList, selectedElem, afterList )

            else if isSelectable first then
                Just ( beforeList ++ [ selectedElem ], first, rest )

            else
                case selectHelp isSelectable [] first rest of
                    Nothing ->
                        Nothing

                    Just ( newBefore, newSelected, newAfter ) ->
                        Just ( selectedElem :: newBefore, newSelected, newAfter )

        ( first :: rest, _ ) ->
            if isSelectable first then
                Just ( [], first, rest ++ selectedElem :: afterList )

            else
                case selectHelp isSelectable rest selectedElem afterList of
                    Nothing ->
                        Nothing

                    Just ( newBefore, newSelected, newAfter ) ->
                        Just ( first :: newBefore, newSelected, newAfter )


{-| Add elements to the end of a `SelectList`.

    import SelectList

    SelectList.fromLists [ 1, 2 ] 3 [ 4 ]
        |> SelectList.append [ 5, 6 ]

    == SelectList.fromLists [ 1 ] 2 [ 3, 4, 5, 6 ]

-}
append : List a -> SelectList a -> SelectList a
append list (SelectList beforeSel sel afterSel) =
    SelectList beforeSel sel (afterSel ++ list)


{-| Add elements to the beginning of a `SelectList`.

    import SelectList

    SelectList.fromLists [ 3 ] 4 [ 5, 6 ]
        |> SelectList.prepend [ 1, 2 ]

    == SelectList.fromLists [ 1, 2, 3 ] 4 [ 5, 6 ]

-}
prepend : List a -> SelectList a -> SelectList a
prepend list (SelectList beforeSel sel afterSel) =
    SelectList (list ++ beforeSel) sel afterSel


{-| Return a `List` containing the elements in a `SelectList`.

    import SelectList

    SelectList.fromLists [ 1, 2, 3 ] 4 [ 5, 6 ]
        |> SelectList.toList

    == [ 1, 2, 3, 4, 5, 6 ]

-}
toList : SelectList a -> List a
toList (SelectList beforeSel sel afterSel) =
    beforeSel ++ sel :: afterSel
