module Api exposing (..)

import Http
import Json.Decode as Decode
import Todo exposing (..)
import Url.Builder as Url

-- Config
baseUrl : String
baseUrl =
    "http://localhost:8080"

-- Endpoints
getTodos :
    { completed : Maybe Bool
    , priority : Maybe Priority
    , limit : Maybe Int
    , offset : Maybe Int
    , sort : Maybe String
    , search : Maybe String
    }
    -> (Result Http.Error TodoResponse -> msg)
    -> Cmd msg
getTodos params toMsg =
    let
        queryParams =
            List.filterMap identity
                [ Maybe.map (\completed -> Url.string "completed" (boolToString completed)) params.completed
                , Maybe.map (\priority -> Url.string "priority" (priorityToString priority)) params.priority
                , Maybe.map (\limit -> Url.string "limit" (intToString limit)) params.limit
                , Maybe.map (\offset -> Url.string "offset" (intToString offset)) params.offset
                , Maybe.map (\sort -> Url.string "sort" sort) params.sort
                , Maybe.map (\search -> Url.string "search" search) params.search
                ]

        url =
            Url.crossOrigin baseUrl [ "todos" ] queryParams
    in
    Http.get
        { url = url
        , expect = Http.expectJson toMsg todoResponseDecoder
        }

-- Helper functions
boolToString : Bool -> String
boolToString bool =
    if bool then
        "true"
    else
        "false"

intToString : Int -> String
intToString =
    String.fromInt
