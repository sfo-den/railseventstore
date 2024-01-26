module Main exposing (main)

import Browser
import Browser.Navigation
import Flags exposing (Flags, RawFlags, buildFlags)
import Html exposing (..)
import Layout
import Page.ShowEvent
import Page.ShowStream
import Route
import Url
import Url.Parser exposing ((</>))
import WrappedModel exposing (..)


main : Program RawFlags Model Msg
main =
    Browser.application
        { init = buildModel
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = ChangeUrl
        , onUrlRequest = ClickedLink
        }


type alias Model =
    { page : Page
    , flags : Maybe Flags
    , key : Browser.Navigation.Key
    , layout : Layout.Model
    }


type Msg
    = ChangeUrl Url.Url
    | ClickedLink Browser.UrlRequest
    | GotLayoutMsg Layout.Msg
    | GotShowEventMsg Page.ShowEvent.Msg
    | GotShowStreamMsg Page.ShowStream.Msg


type Page
    = NotFound
    | ShowEvent Page.ShowEvent.Model
    | ShowStream Page.ShowStream.Model


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        ShowEvent pageModel ->
            Sub.map GotShowEventMsg (Page.ShowEvent.subscriptions pageModel)

        _ ->
            Sub.none


buildModel : RawFlags -> Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
buildModel rawFlags location key =
    let
        initModel =
            { page = NotFound
            , flags = buildFlags rawFlags
            , key = key
            , layout = Layout.buildModel
            }
    in
    urlUpdate initModel location


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( ChangeUrl location, _ ) ->
            urlUpdate model location

        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Browser.Navigation.pushUrl model.key (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Browser.Navigation.load url
                    )

        ( GotShowStreamMsg showStreamUIMsg, ShowStream showStreamModel ) ->
            let
                ( subModel, subCmd ) =
                    Page.ShowStream.update showStreamUIMsg showStreamModel
            in
            ( { model | page = ShowStream subModel }
            , Cmd.map GotShowStreamMsg subCmd
            )

        ( GotShowEventMsg openedEventUIMsg, ShowEvent showEventModel ) ->
            let
                ( subModel, subCmd ) =
                    Page.ShowEvent.update openedEventUIMsg showEventModel
            in
            ( { model | page = ShowEvent subModel }
            , Cmd.map GotShowEventMsg subCmd
            )

        ( GotLayoutMsg layoutMsg, _ ) ->
            case model.flags of
                Nothing ->
                    ( model, Cmd.none )

                Just flags ->
                    let
                        ( layoutModel, layoutCmd ) =
                            Layout.update layoutMsg (WrappedModel model.layout model.key flags)
                    in
                    ( { model | layout = layoutModel }, Cmd.map GotLayoutMsg layoutCmd )

        ( _, _ ) ->
            ( model, Cmd.none )


urlUpdate : Model -> Url.Url -> ( Model, Cmd Msg )
urlUpdate model location =
    case model.flags of
        Nothing ->
            ( model, Cmd.none )

        Just flags ->
            case Route.decodeLocation flags.rootUrl location of
                Just (Route.BrowseEvents encodedStreamId) ->
                    case Url.percentDecode encodedStreamId of
                        Just streamId ->
                            ( { model | page = ShowStream (Page.ShowStream.initModel flags streamId) }
                            , Cmd.map GotShowStreamMsg (Page.ShowStream.initCmd flags streamId)
                            )

                        Nothing ->
                            ( { model | page = NotFound }, Cmd.none )

                Just (Route.ShowEvent encodedEventId) ->
                    case Url.percentDecode encodedEventId of
                        Just eventId ->
                            ( { model | page = ShowEvent (Page.ShowEvent.initModel flags eventId) }
                            , Cmd.map GotShowEventMsg (Page.ShowEvent.initCmd flags eventId)
                            )

                        Nothing ->
                            ( { model | page = NotFound }, Cmd.none )

                Nothing ->
                    ( { model | page = NotFound }, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    case model.flags of
        Nothing ->
            { title = fullTitle Nothing
            , body =
                [ div []
                    [ Layout.viewIncorrectConfig
                    ]
                ]
            }

        Just flags ->
            let
                ( title, content ) =
                    viewPage model.page

                wrappedModel =
                    WrappedModel model.layout model.key flags
            in
            { title = fullTitle title
            , body = [ div [] [ Layout.view GotLayoutMsg wrappedModel content ] ]
            }


fullTitle : Maybe String -> String
fullTitle maybePageTitle =
    case maybePageTitle of
        Just pageTitle ->
            "RubyEventStore::Browser - " ++ pageTitle

        Nothing ->
            "RubyEventStore::Browser"


viewPage : Page -> ( Maybe String, Html Msg )
viewPage page =
    case page of
        ShowStream pageModel ->
            let
                ( title, content ) =
                    Page.ShowStream.view pageModel 
            in
            ( Just title, Html.map GotShowStreamMsg content )

        ShowEvent pageModel ->
            let
                ( title, content ) =
                    Page.ShowEvent.view pageModel 
            in
            ( Just title, Html.map GotShowEventMsg content )

        NotFound ->
            ( Nothing, Layout.viewNotFound )
