module Vendor.Date.Local exposing
    ( international, french, german, brazilian, greek, dutch
    , Local, Months, WeekDays, TimeZones
    )

{-| A record type to store localized time formatting information.

@docs international, french, german, brazilian, greek, dutch

@docs Local, Months, WeekDays, TimeZones

-}

import Dict exposing (Dict)


{-| A collection of strings and formats for localizing formats.

Time zones and default formats are not implemented,
but included to avoid possible version conflicts in the future.

-}
type alias Local =
    { date :
        { months : Months
        , monthsAbbrev : Months
        , wdays : WeekDays
        , wdaysAbbrev : WeekDays
        , defaultFormat :
            Maybe String

        -- for %x
        }
    , time :
        { am : String
        , pm : String
        , defaultFormat :
            Maybe String

        -- for %X
        }
    , timeZones :
        Maybe TimeZones

    -- for %Z
    , defaultFormat :
        Maybe String

    -- for %c
    }


{-| A record of names for the months of the year.
-}
type alias Months =
    { jan : String
    , feb : String
    , mar : String
    , apr : String
    , may : String
    , jun : String
    , jul : String
    , aug : String
    , sep : String
    , oct : String
    , nov : String
    , dec : String
    }


{-| A record of names for the days of the week.
-}
type alias WeekDays =
    { mon : String
    , tue : String
    , wed : String
    , thu : String
    , fri : String
    , sat : String
    , sun : String
    }


{-| Maps from %z type string (+hhmm or -hhmm) to timezone name or abbreviation.

Not currently implemented.

-}
type alias TimeZones =
    Dict String String


{-| A default set of localizations.
-}
international : Local
international =
    { date =
        { months =
            { jan = "January"
            , feb = "February"
            , mar = "March"
            , apr = "April"
            , may = "May"
            , jun = "June"
            , jul = "July"
            , aug = "August"
            , sep = "September"
            , oct = "October"
            , nov = "November"
            , dec = "December"
            }
        , monthsAbbrev =
            { jan = "Jan"
            , feb = "Feb"
            , mar = "Mar"
            , apr = "Apr"
            , may = "May"
            , jun = "Jun"
            , jul = "Jul"
            , aug = "Aug"
            , sep = "Sep"
            , oct = "Oct"
            , nov = "Nov"
            , dec = "Dec"
            }
        , wdays =
            { mon = "Monday"
            , tue = "Tuesday"
            , wed = "Wednesday"
            , thu = "Thursday"
            , fri = "Friday"
            , sat = "Saturday"
            , sun = "Sunday"
            }
        , wdaysAbbrev =
            { mon = "Mon"
            , tue = "Tue"
            , wed = "Wed"
            , thu = "Thu"
            , fri = "Fri"
            , sat = "Sat"
            , sun = "Sun"
            }
        , defaultFormat = Nothing
        }
    , time =
        { am = "am"
        , pm = "pm"
        , defaultFormat = Nothing
        }
    , timeZones = Nothing
    , defaultFormat = Nothing
    }


{-| French set of localizations.
-}
french : Local
french =
    { date =
        { months =
            { jan = "Janvier"
            , feb = "Février"
            , mar = "Mars"
            , apr = "Avril"
            , may = "Mai"
            , jun = "Juin"
            , jul = "Juillet"
            , aug = "Août"
            , sep = "Septembre"
            , oct = "Octobre"
            , nov = "Novembre"
            , dec = "Décembre"
            }
        , monthsAbbrev =
            { jan = "Jan"
            , feb = "Fév"
            , mar = "Mar"
            , apr = "Avr"
            , may = "Mai"
            , jun = "Jui"
            , jul = "Jul"
            , aug = "Aoû"
            , sep = "Sep"
            , oct = "Oct"
            , nov = "Nov"
            , dec = "Déc"
            }
        , wdays =
            { mon = "Lundi"
            , tue = "Mardi"
            , wed = "Mercredi"
            , thu = "Jeudi"
            , fri = "Vendredi"
            , sat = "Samedi"
            , sun = "Dimanche"
            }
        , wdaysAbbrev =
            { mon = "Lun"
            , tue = "Mar"
            , wed = "Mer"
            , thu = "Jeu"
            , fri = "Ven"
            , sat = "Sam"
            , sun = "Dim"
            }
        , defaultFormat = Nothing
        }
    , time =
        { am = "am"
        , pm = "pm"
        , defaultFormat = Nothing
        }
    , timeZones = Nothing
    , defaultFormat = Nothing
    }


{-| Brazilian set of localizations.
-}
brazilian : Local
brazilian =
    { date =
        { months =
            { jan = "Janeiro"
            , feb = "Fevereiro"
            , mar = "Março"
            , apr = "Abril"
            , may = "Maio"
            , jun = "Junho"
            , jul = "Julho"
            , aug = "Agosto"
            , sep = "Setembro"
            , oct = "Outubro"
            , nov = "Novembro"
            , dec = "Dezembro"
            }
        , monthsAbbrev =
            { jan = "Jan"
            , feb = "Fev"
            , mar = "Mar"
            , apr = "Abr"
            , may = "Mai"
            , jun = "Jun"
            , jul = "Jul"
            , aug = "Ago"
            , sep = "Set"
            , oct = "Out"
            , nov = "Nov"
            , dec = "Dez"
            }
        , wdays =
            { mon = "Segunda-feira"
            , tue = "Terça-feira"
            , wed = "Quarta-feira"
            , thu = "Quinta-feira"
            , fri = "Sexta-feira"
            , sat = "Sábado"
            , sun = "Domingo"
            }
        , wdaysAbbrev =
            { mon = "Seg"
            , tue = "Ter"
            , wed = "Qua"
            , thu = "Qui"
            , fri = "Sex"
            , sat = "Sáb"
            , sun = "Dom"
            }
        , defaultFormat = Just "%e de %B de %Y"
        }
    , time =
        { am = "am"
        , pm = "pm"
        , defaultFormat = Just "%k:%M"
        }
    , timeZones = Nothing
    , defaultFormat = Nothing
    }


{-| German set of localizations.
-}
german : Local
german =
    { date =
        { months =
            { jan = "Januar"
            , feb = "Februar"
            , mar = "März"
            , apr = "April"
            , may = "Mai"
            , jun = "Juni"
            , jul = "Juli"
            , aug = "August"
            , sep = "September"
            , oct = "Oktober"
            , nov = "November"
            , dec = "Dezember"
            }
        , monthsAbbrev =
            { jan = "Jan"
            , feb = "Feb"
            , mar = "Mär"
            , apr = "Apr"
            , may = "Mai"
            , jun = "Jun"
            , jul = "Jul"
            , aug = "Aug"
            , sep = "Sep"
            , oct = "Okt"
            , nov = "Nov"
            , dec = "Dez"
            }
        , wdays =
            { mon = "Montag"
            , tue = "Dienstag"
            , wed = "Mittwoch"
            , thu = "Donnerstag"
            , fri = "Freitag"
            , sat = "Samstag"
            , sun = "Sonntag"
            }
        , wdaysAbbrev =
            { mon = "Mo"
            , tue = "Di"
            , wed = "Mi"
            , thu = "Do"
            , fri = "Fr"
            , sat = "Sa"
            , sun = "So"
            }
        , defaultFormat = Just "%e. %B %Y"
        }
    , time =
        { am = "am"
        , pm = "pm"
        , defaultFormat = Just "%k:%M"
        }
    , timeZones = Nothing
    , defaultFormat = Nothing
    }


{-| Greek set of localizations.
-}
greek : Local
greek =
    { date =
        { months =
            { jan = "Ιανουαρίου"
            , feb = "Φεβρουαρίου"
            , mar = "Μαρτίου"
            , apr = "Απριλίου"
            , may = "Μαΐου"
            , jun = "Ιουνίου"
            , jul = "Ιουλίου"
            , aug = "Αυγούστου"
            , sep = "Σεπτεμβρίου"
            , oct = "Οκτωβρίου"
            , nov = "Νοεμβρίου"
            , dec = "Δεκεμβρίου"
            }
        , monthsAbbrev =
            { jan = "Ιαν"
            , feb = "Φεβ"
            , mar = "Μαρ"
            , apr = "Απρ"
            , may = "Μαϊ"
            , jun = "Ιουν"
            , jul = "Ιουλ"
            , aug = "Αυγ"
            , sep = "Σεπ"
            , oct = "Οκτ"
            , nov = "Νοε"
            , dec = "Δεκ"
            }
        , wdays =
            { mon = "Δευτέρα"
            , tue = "Τρίτη"
            , wed = "Τετάρτη"
            , thu = "Πέμπτη"
            , fri = "Παρασκευή"
            , sat = "Σάββατο"
            , sun = "Κυριακή"
            }
        , wdaysAbbrev =
            { mon = "Δευ"
            , tue = "Τρι"
            , wed = "Τετ"
            , thu = "Πεμ"
            , fri = "Παρ"
            , sat = "Σαβ"
            , sun = "Κυρ"
            }
        , defaultFormat = Nothing
        }
    , time =
        { am = "πμ"
        , pm = "μμ"
        , defaultFormat = Nothing
        }
    , timeZones = Nothing
    , defaultFormat = Nothing
    }


{-| Dutch set of localizations.
-}
dutch : Local
dutch =
    { date =
        { months =
            { jan = "januari"
            , feb = "februari"
            , mar = "maart"
            , apr = "april"
            , may = "mei"
            , jun = "juni"
            , jul = "juli"
            , aug = "augustus"
            , sep = "september"
            , oct = "oktober"
            , nov = "november"
            , dec = "december"
            }
        , monthsAbbrev =
            { jan = "jan"
            , feb = "feb"
            , mar = "mrt"
            , apr = "apr"
            , may = "mei"
            , jun = "jun"
            , jul = "jul"
            , aug = "aug"
            , sep = "sep"
            , oct = "okt"
            , nov = "nov"
            , dec = "dec"
            }
        , wdays =
            { mon = "maandag"
            , tue = "dinsdag"
            , wed = "woensdag"
            , thu = "donderdag"
            , fri = "vrijdag"
            , sat = "zaterdag"
            , sun = "zondag"
            }
        , wdaysAbbrev =
            { mon = "ma"
            , tue = "di"
            , wed = "wo"
            , thu = "do"
            , fri = "vr"
            , sat = "za"
            , sun = "zo"
            }
        , defaultFormat = Nothing
        }
    , time =
        { am = "am"
        , pm = "pm"
        , defaultFormat = Just "%H:%M"
        }
    , timeZones = Nothing
    , defaultFormat = Nothing
    }
