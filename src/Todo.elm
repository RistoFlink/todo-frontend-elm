module Todo exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Time

-- Types

type Priority
    = High
    | Medium
    | Low

type alias Todo =
    { id : Int
    , title : String
    , completed : Bool
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    , dueDate : Maybe Time.Posix
    , priority : Priority
    }

type alias TodoResponse =
    { todos : List Todo
    , totalCount : Int
    , limit : Int
    , offset : Int
    }

type alias CreateTodoPayload =
    { title: String
    , completed: Maybe Bool
    , duedate: Maybe Time.Posix
    , priority : Maybe Priority
    }

type alias TodoStats =
    { priorityStats : PriorityStats
    , completionStats : CompletionStats
    , overdueCount : Int
    , dueSoonCount : Int
    }

type alias PriorityStats =
    { high : Int
    , medium : Int
    , low : Int
    , priorityTotal : Int
    }

type alias CompletionStats = 
    { completed : Int
    , incomple : Int
    , completionTotal : Int
    }

-- JSON decoders
priorityDecoder : Decoder Priority
priorityDecoder =
    Decode.string |> Decode.andThen (\str ->
        case str of
            "High" -> Decode.succeed High
            "Medium" -> Decode.succeed Medium
            "Low" -> Decode.succeed Low
            _ -> Decode.fail ("Unknown priority: " ++ str)
    )

todoDecoder : Decoder Todo
todoDecoder =
    Decode.map7 Todo
        (Decode.field "id" Decode.int)
        (Decode.field "title" Decode.string)
        (Decode.field "completed" Decode.bool)
        (Decode.field "createdAt" (Decode.map Time.millisToPosix Decode.int))
        (Decode.field "updatedAt" (Decode.map Time.millisToPosix Decode.int))
        (Decode.field "dueDate" (Decode.nullable (Decode.map Time.millisToPosix Decode.int)))
        (Decode.field "priority" priorityDecoder)


-- Helper functions
priorityToString : Priority -> String
priorityToString priority =
    case priority of
        High -> "High"
        Medium -> "Medium"
        Low -> "Low"