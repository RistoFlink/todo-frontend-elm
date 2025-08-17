module Todo exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Time



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