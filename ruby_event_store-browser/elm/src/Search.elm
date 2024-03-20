module Search exposing (..)

import Api exposing (SearchStream, getSearchStreams)
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, id, list, placeholder, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Page.ShowStream exposing (Msg(..))


type alias Stream =
    String


type alias Model =
    { streams : List Stream
    , value : Stream
    }


type Msg
    = StreamChanged Stream
    | GoToStream Stream
    | SearchedStreamsFetched (Result Http.Error (List SearchStream))


init : Model
init =
    { streams = []
    , value = ""
    }


searchStreams : Flags -> Stream -> Cmd Msg
searchStreams flags stream =
    getSearchStreams SearchedStreamsFetched flags stream


update : Msg -> Model -> Flags -> (String -> Cmd Msg) -> ( Model, Cmd Msg )
update msg model flags onSubmit =
    case msg of
        StreamChanged stream ->
            ( { model | value = stream }, searchStreams flags stream )

        GoToStream stream ->
            ( model, onSubmit stream )

        SearchedStreamsFetched (Ok streams) ->
            ( { model | streams = List.map .streamId streams }, Cmd.none )

        SearchedStreamsFetched (Err _) ->
            ( { model | streams = [] }, Cmd.none )


view : Model -> Html Msg
view model =
    form [ onSubmit (GoToStream model.value) ]
        [ input
            [ class "rounded px-4 py-2"
            , value model.value
            , onInput StreamChanged
            , placeholder "Go to stream..."
            , list "streams"
            ]
            []
        , datalist
            [ id "streams" ]
            (List.map
                (\stream -> option [] [ text stream ])
                model.streams
            )
        ]
