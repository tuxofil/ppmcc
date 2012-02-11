#!/usr/bin/env escript
%%! -smp enable

%%% ---------------------------------------------------------------------
%%% File    : ppmcc
%%% Version : 1.0
%%% Author  : Aleksey Morarash <aleksey.morarash@gmail.com>
%%% Description: Pearson product-moment correlation coefficient
%%%              calculator.
%%% Created : Sat, 10 Dec 2011 11:30:00 +02:00
%%% License : FreeBSD
%%%           Full license contents available at LICENSE file.
%%%           This is free software: you are free to change and
%%%           redistribute it. There is NO WARRANTY, to the extent
%%%           permitted by law.
%%% ---------------------------------------------------------------------

%% ----------------------------------------------------------------------
%% Includes and common definitions
%% ----------------------------------------------------------------------

-include_lib("wx/include/wx.hrl").

-define(default_precision, 4).

%% ----------------------------------------------------------------------
%% Calculations section
%% ----------------------------------------------------------------------

calc_average(List) ->
    lists:sum(List) / length(List).

calc_x_y_table(CorrelationSequences, Xave, Yave) ->
    lists:map(
      fun({X, Y}) ->
              DX = X - Xave,
              DY = Y - Yave,
              [X, Y, DX, DY, DX * DY, DX * DX, DY * DY]
      end, CorrelationSequences).

calc_r(DXDYsum, DXDXsum, DYDYsum)
  when DXDXsum /= 0, DYDYsum /= 0 ->
    DXDYsum / math:sqrt(DXDXsum * DYDYsum);
calc_r(_DXDYsum, DXDXsum, _DYDYsum)
  when DXDXsum == 0 ->
    s_error("Sum of dx squares equals zero!", []),
    throw({error, {zero, dxdxsum}});
calc_r(_DXDYsum, _DXDXsum, DYDYsum)
  when DYDYsum == 0 ->
    s_error("Sum of dy squares equals zero!", []),
    throw({error, {zero, dydysum}}).

calc_m(R, N) when N > 2 ->
    math:sqrt((1 - R * R) / (N - 2)).

calc_t(R, M) when M /= 0 ->
    R / M.

calc_f(N) ->
    N + N - 2.

calc_reliability_factor(F, T) ->
    case [Tail || [H | Tail] <- student_table(), H == F] of
        [Ts] ->
            List = lists:zip(Ts, [0.8, 0.9, 0.95, 0.98, 0.99, 0.995, 0.998, 0.999]),
            %% todo:
            Tmod =
                if T < 0 -> - T;
                   true -> T
                end,
            calc_reliability_factor_(Tmod, List);
        [] -> undefined
    end.
calc_reliability_factor_(T, [{H, F} | _]) when T < H ->
    {0, F};
calc_reliability_factor_(T, [{T, F} | _]) ->
    {F, F};
calc_reliability_factor_(T, [{H1, F1}, {H2, F2} | _])
  when T >= H1, T =< H2 ->
    {F1, F2};
calc_reliability_factor_(T, [{H, F}]) when T > H ->
    {F, 1};
calc_reliability_factor_(T, [_ | Tail]) ->
    calc_reliability_factor_(T, Tail).

student_table() ->
    [
     %%     0.80    0.90     0.95     0.98     0.99     0.995     0.998     0.999
     %% ---------------------------------------------------------------------------
     [1,   3.0770, 6.3130, 12.7060, 31.8200, 63.6560, 127.6560, 318.3060, 636.6190],
     [2,   1.8850, 2.9200,  4.3020,  6.9640,  9.9240,  14.0890,  22.3270,  31.5990],
     [3,   1.6377, 2.3534,  3.1820,  4.5400,  5.8400,   7.4580,  10.2140,  12.9240],
     [4,   1.5332, 2.1318,  2.7760,  3.7460,  4.6040,   5.5970,   7.1730,   8.6100],
     [5,   1.4759, 2.0150,  2.5700,  3.6490,  4.0321,   4.7730,   5.8930,   6.8630],
     [6,   1.4390, 1.9430,  2.4460,  3.1420,  3.7070,   4.3160,   5.2070,   5.9580],
     [7,   1.4149, 1.8946,  2.3646,  2.9980,  3.4995,   4.2293,   4.7850,   5.4079],
     [8,   1.3968, 1.8596,  2.3060,  2.8965,  3.3554,   3.8320,   4.5008,   5.0413],
     [9,   1.3830, 1.8331,  2.2622,  2.8214,  3.2498,   3.6897,   4.2968,   4.7800],
     [10,  1.3720, 1.8125,  2.2281,  2.7638,  3.1693,   3.5814,   4.1437,   4.5869],
     [11,  1.3630, 1.7950,  2.2010,  2.7180,  3.1050,   3.4960,   4.0240,   4.4370],
     [12,  1.3562, 1.7823,  2.1788,  2.6810,  3.0845,   3.4284,   3.9290,   4.1780],
     [13,  1.3502, 1.7709,  2.1604,  2.6503,  3.1123,   3.3725,   3.8520,   4.2200],
     [14,  1.3450, 1.7613,  2.1448,  2.6245,  2.9760,   3.3257,   3.7870,   4.1400],
     [15,  1.3406, 1.7530,  2.1314,  2.6025,  2.9467,   3.2860,   3.7320,   4.0720],
     [16,  1.3360, 1.7450,  2.1190,  2.5830,  2.9200,   3.2520,   3.6860,   4.0150],
     [17,  1.3334, 1.7396,  2.1098,  2.5668,  2.8982,   3.2224,   3.6458,   3.9650],
     [18,  1.3304, 1.7341,  2.1009,  2.5514,  2.8784,   3.1966,   3.6105,   3.9216],
     [19,  1.3277, 1.7291,  2.0930,  2.5395,  2.8609,   3.1737,   3.5794,   3.8834],
     [20,  1.3253, 1.7247,  2.0860,  2.5280,  2.8453,   3.1534,   3.5518,   3.8495],
     [21,  1.3230, 1.7200,  2.0790,  2.5170,  2.8310,   3.1350,   3.5270,   3.8190],
     [22,  1.3212, 1.7117,  2.0739,  2.5083,  2.8188,   3.1188,   3.5050,   3.7921],
     [23,  1.3195, 1.7139,  2.0687,  2.4999,  2.8073,   3.1040,   3.4850,   3.7676],
     [24,  1.3178, 1.7109,  2.0639,  2.4922,  2.7969,   3.0905,   3.4668,   3.7454],
     [25,  1.3163, 1.7081,  2.0595,  2.4851,  2.7874,   3.0782,   3.4502,   3.7251],
     [26,  1.3150, 1.7050,  2.0590,  2.4780,  2.7780,   3.0660,   3.4360,   3.7060],
     [27,  1.3137, 1.7033,  2.0518,  2.4727,  2.7707,   3.0565,   3.4210,   3.6896],
     [28,  1.3125, 1.7011,  2.0484,  2.4671,  2.7633,   3.0469,   3.4082,   3.6739],
     [29,  1.3114, 1.6991,  2.0452,  2.4620,  2.7564,   3.0360,   3.3962,   3.8494],
     [30,  1.3104, 1.6973,  2.0423,  2.4573,  2.7500,   3.0298,   3.3852,   3.6460],
     [32,  1.3080, 1.6930,  2.0360,  2.4480,  2.7380,   3.0140,   3.3650,   3.6210],
     [34,  1.3070, 1.6909,  2.0322,  2.4411,  2.7284,   3.9520,   3.3479,   3.6007],
     [36,  1.3050, 1.6883,  2.0281,  2.4345,  2.7195,   9.4900,   3.3326,   3.5821],
     [38,  1.3042, 1.6860,  2.0244,  2.4286,  2.7116,   3.9808,   3.3190,   3.5657],
     [40,  1.3030, 1.6839,  2.0211,  2.4233,  2.7045,   3.9712,   3.3069,   3.5510],
     [42,  1.3200, 1.6820,  2.0180,  2.4180,  2.6980,   2.6930,   3.2960,   3.5370],
     [44,  1.3010, 1.6802,  2.0154,  2.4141,  2.6923,   3.9555,   3.2861,   3.5258],
     [46,  1.3000, 1.6767,  2.0129,  2.4102,  2.6870,   3.9488,   3.2771,   3.5150],
     [48,  1.2990, 1.6772,  2.0106,  2.4056,  2.6822,   3.9426,   3.2689,   3.5051],
     [50,  1.2980, 1.6759,  2.0086,  2.4033,  2.6778,   3.9370,   3.2614,   3.4060],
     [55,  1.2997, 1.6730,  2.0040,  2.3960,  2.6680,   2.9240,   3.2560,   3.4760],
     [60,  1.2958, 1.6706,  2.0003,  2.3901,  2.6603,   3.9146,   3.2317,   3.4602],
     [65,  1.2947, 1.6686,  1.9970,  2.3851,  2.6536,   3.9060,   3.2204,   3.4466],
     [70,  1.2938, 1.6689,  1.9944,  2.3808,  2.6479,   3.8987,   3.2108,   3.4350],
     [80,  1.2820, 1.6640,  1.9900,  2.3730,  2.6380,   2.8870,   3.1950,   3.4160],
     [90,  1.2910, 1.6620,  1.9867,  2.3885,  2.6316,   2.8779,   3.1833,   3.4019],
     [100, 1.2901, 1.6602,  1.9840,  2.3642,  2.6259,   2.8707,   3.1737,   3.3905],
     [120, 1.2888, 1.6577,  1.9719,  2.3578,  2.6174,   2.8598,   3.1595,   3.3735],
     [150, 1.2872, 1.6551,  1.9759,  2.3515,  2.6090,   2.8482,   3.1455,   3.3566],
     [200, 1.2858, 1.6525,  1.9719,  2.3451,  2.6006,   2.8385,   3.1315,   3.3398],
     [250, 1.2849, 1.6510,  1.9695,  2.3414,  2.5966,   2.8222,   3.1232,   3.3299],
     [300, 1.2844, 1.6499,  1.9679,  2.3388,  2.5923,   2.8279,   3.1176,   3.3233],
     [400, 1.2837, 1.6487,  1.9659,  2.3357,  2.5882,   2.8227,   3.1107,   3.3150],
     [500, 1.2830, 1.6470,  1.9640,  2.3330,  2.7850,   2.8190,   3.1060,   3.3100]
    ].

%% @doc Payload.
%% @spec do_calculations(N, CorrelationSequences) -> none
%%     N = integer(),
%%     CorrelationSequences = [{X, Y}],
%%         X = Y = float()
do_calculations(0, _) ->
    s_error("There is no meaning input data at all.");
do_calculations(N, _) when N < 6 ->
    s_error("Correlation sequence must have at least 6 items "
            "but you have only ~w.", [N]);
do_calculations(N, CorrelationSequences) ->
    if N < 7 ->
            s_warning("Correlation sequence suggest "
                      "to have 7 or more items!");
       true -> nop
    end,
    {Xs, Ys} = lists:unzip(CorrelationSequences),
    print_value("x average",
                Xave = calc_average(Xs)),
    print_value("y average",
                Yave = calc_average(Ys)),
    print_table(["x", "y", "dx", "dy", "dx * dy", "dx^2", "dy^2"],
                Table = calc_x_y_table(CorrelationSequences, Xave, Yave)),
    print_value("dx * dy sum",
                DXDYsum = lists:sum([E || [_,_,_,_,E,_,_] <- Table])),
    print_value("dx * dx sum",
                DXDXsum = lists:sum([E || [_,_,_,_,_,E,_] <- Table])),
    print_value("dy * dy sum",
                DYDYsum = lists:sum([E || [_,_,_,_,_,_,E] <- Table])),
    print_value("Pearson product-moment correlation coefficient (r)",
                R = calc_r(DXDYsum, DXDXsum, DYDYsum),
                true),
    print_value("Correlation factor average infelicity (m)",
                M = calc_m(R, N),
                true),
    print_value("Correlation factor reliability (t)",
                T = calc_t(R, M),
                true),
    print_value("f",
                F = calc_f(N),
                true),
    case calc_reliability_factor(F, T) of
        {Pmin, Pmax} ->
            print_value("P min", 1 - Pmin, true),
            print_value("P max", 1 - Pmax, true);
        _ ->
            s_error("No such element (~w) in Student criteria table", [F])
    end.

%% ----------------------------------------------------------------------
%% Main section
%% ----------------------------------------------------------------------

-define(cfg_batch, batch).
-define(cfg_quiet, quiet).
-define(cfg_plain, plain).
-define(cfg_precision, precision).

-define(ctl_frame, ctl_frame).
-define(ctl_quiet, ctl_quiet).
-define(ctl_plain, ctl_plain).
-define(ctl_precision, ctl_precision).
-define(ctl_notebook, ctl_notebook).
-define(ctl_tab1, ctl_tab1).
-define(ctl_tab2, ctl_tab2).

-define(input, output).

%% @doc Script entry point.
%% @spec main(Args) -> none
%%     Args = [string()]
main(Args) ->
    lists:foreach(
      fun(Arg) ->
              process_arg(Arg)
      end, Args),
    case get(?cfg_batch) of
        true ->
            {ok, PairsCount, Pairs} = read_input(),
            do_calculations(PairsCount, Pairs);
        _ ->
            Wx = wx:new(),
            {Frame,
             Precision, Quiet, DrawTables,
             Notebook, Tab1, Tab2} =
                wx:batch(fun() -> wxcreate_window(Wx) end),
            put(?ctl_frame, Frame),
            put(?ctl_precision, Precision),
            put(?ctl_quiet, Quiet),
            put(?ctl_plain, DrawTables),
            put(?ctl_notebook, Notebook),
            put(?ctl_tab1, Tab1),
            put(?ctl_tab2, Tab2),
            wxWindow:show(Frame),
            wxloop(),
            wx:destroy()
    end.

%% @doc Processes script argument.
%% @spec process_arg(String) -> none
%%     String = string()
process_arg("-h") ->
    io:format(help()),
    halt(1);
process_arg("--help") ->
    io:format(help()),
    halt(1);
process_arg("-b") ->
    put(?cfg_batch, true);
process_arg("--batch") ->
    put(?cfg_batch, true);
process_arg("-q") ->
    put(?cfg_quiet, true);
process_arg("--quiet") ->
    put(?cfg_quiet, true);
process_arg("--plain") ->
    put(?cfg_plain, true);
process_arg("-p" ++ Str) ->
    put(?cfg_precision,
        try list_to_integer(Str) of
            Int when Int > 0 -> Int;
            _ ->
                s_error("Precision must be greater than 0")
        catch
            _:_ ->
                s_error("Bad precision number: \"~s\"", [Str])
        end);
process_arg(Other) ->
    s_error("Unknown option: \"~s\"", [Other]).

%% @doc Reads source values from stdin.
%% @spec read_input() -> {PairsCount, Pairs}
%%     PairsCount = integer(),
%%     Pairs = [{X, Y}],
%%         X = Y = float()
read_input() ->
    try read_input(0, 0, []) of
        {ok, _, _} = Ok ->
            Ok;
        {error, _} = Error ->
            Error;
        Other ->
            {error, {bad_result, Other}}
    catch
        _:{error, _Reason} = Error ->
            Error;
        Type:Reason ->
            {error, {Type, Reason, erlang:get_stacktrace()}}
    end.
read_input(LinesRead, PairsCount, Result) ->
    LineNo = LinesRead + 1,
    case get_line() of
        eof -> {ok, PairsCount, lists:reverse(Result)};
        {error, Reason} = Error ->
            s_error("Unable to read ~w line: ~p",
                    [LineNo, Reason]),
            throw(Error);
        Line ->
            case strip(Line, " \t\r\n") of
                "#" ++ _Comment ->
                    read_input(LineNo, PairsCount, Result);
                "" ->
                    read_input(LineNo, PairsCount, Result);
                Stripped ->
                    case string:tokens(Stripped, " \t,;:") of
                        [Str1, Str2] ->
                            read_input(
                              LineNo, PairsCount + 1,
                              [{parse_float(LineNo, Str1),
                                parse_float(LineNo, Str2)} |
                               Result]);
                        _ ->
                            s_error("Unable to parse line ~w: \"~s\"",
                                    [LineNo, Stripped]),
                            throw({error, {parse, LineNo, Stripped}})
                    end
            end
    end.
get_line() ->
    case get(?cfg_batch) of
        true ->
            io:get_line("");
        _ ->
            Input =
                case get(?input) of
                    L when is_list(L) -> L;
                    _ ->
                        wxStyledTextCtrl:getText(get(?ctl_tab1))
                end,
            case get_line_(Input, []) of
                eof -> eof;
                {Line, Tail} ->
                    put(?input, Tail),
                    Line
            end
    end.
get_line_([$\n | Tail], Line) ->
    {lists:reverse(Line), Tail};
get_line_([H | Tail], Line) ->
    get_line_(Tail, [H | Line]);
get_line_([], [_ | _] = Line) ->
    {lists:reverse(Line), []};
get_line_([], []) -> eof.

%% @doc Strips chars from beginning and ending of specified string.
%% @spec strip(String, Chars) -> ResultString
%%     String = Chars = ResultString = string()
strip(String, Chars) ->
    lists:reverse(strip_(lists:reverse(strip_(String, Chars)), Chars)).
strip_([H | Tail] = String, Chars) ->
    case lists:member(H, Chars) of
        true -> strip_(Tail, Chars);
        _ -> String
    end;
strip_([], _Chars) -> [].

%% @doc Converts float number from textual representation.
%% @spec parse_float(LineNo, String) -> Float
%%     LineNo = integer(),
%%     String = string(),
%%     Float = float()
parse_float(LineNo, String) ->
    try list_to_float(String)
    catch
        _:_ ->
            %% workaround for crashes like list_to_float("1")
            try list_to_integer(String) / 1
            catch
                _:_ ->
                    s_error("Bad number at line ~w: \"~s\"",
                            [LineNo, String]),
                    throw({error, {parse_number, LineNo, String}})
            end
    end.

%% ----------------------------------------------------------------------
%% Formatting section
%% ----------------------------------------------------------------------

%% @doc Outputs formatted string and halt script execution.
%% @spec s_error(Format) -> none
%% @spec s_error(Format, Arguments) -> none
%%     Format = string(),
%%     Arguments = list()
s_error(Str) -> s_error(Str, []).
s_error(Str, Args) ->
    case get(?cfg_batch) of
        true ->
            io:format(standard_error, "Error: " ++ Str ++ "~n", Args),
            halt(1);
        _ ->
            Content = lists:flatten(io_lib:format(Str, Args)),
            Modal =
                wxMessageDialog:new(
                  get(?ctl_frame), Content,
                  [{style, ?wxOK bor ?wxICON_ERROR},
                   {caption, "Error"}]),
            wxDialog:showModal(Modal),
            wxDialog:destroy(Modal),
            {error, {Str, Args}}
    end.

%% @doc Outputs formatted warning string.
%% @spec s_warning(Format) -> none
%% @spec s_warning(Format, Args) -> none
%%     Format = string(),
%%     Arguments = list()
s_warning(Format) ->
    s_warning(Format, []).
s_warning(Format, Args) ->
    case get(?cfg_batch) of
        true ->
            io:format("Warning: " ++ Format ++ "~n", Args);
        _ ->
            Content = lists:flatten(io_lib:format(Format, Args)),
            Modal =
                wxMessageDialog:new(
                  get(?ctl_frame), Content,
                  [{style, ?wxOK bor ?wxICON_EXCLAMATION},
                   {caption, "Warning"}]),
            wxDialog:showModal(Modal),
            wxDialog:destroy(Modal)
    end.

%% @doc Show help and exit.
%% @spec help() -> string()
help() ->
    lists:flatten(
      io_lib:format(
        "Usage: ~s [-h|--help] [-v] [-pPrecision] [--plain]~n~n"
        "Options:~n"
        "\t-h, --help  - show this memo;~n"
        "\t-b, --batch - run in batch mode instead of GUI;~n"
        "\t-q, --quiet - quiet mode. Only final results will be~n"
        "\t              shown (by default all intermediate results~n"
        "\t              will be shown);~n"
        "\t-pPrecision - sets desired precision for float numbers.~n"
        "\t              Default is 4;~n"
        "\t--plain     - do not draw tables. Will show TAB-separated~n"
        "\t              values instead.~n~n"
        "When in batch mode, reads input data from standard input and~n"
        "writes results to standard output. Input stream can contain~n"
        "lines beginned with \"#\" character - such lines will be~n"
        "ignored as comments. Empty lines will be ignored too.~n"
        "Each line with source data must contain two numbers (X and Y),~n"
        "separated by one or more spaces or tabs.~n"
        "~n",
        [escript:script_name()])).

%% @doc Prints table supplied if 'quiet' mode is disabled.
%% @spec print_table(Titles, Rows) -> ok
%% @spec print_table(Titles, Rows, Force) -> ok
%%     Titles = [ColumnTitle],
%%         ColumnTitle = string(),
%%     Rows = [Row],
%%         Row = [Cell],
%%         Cell = string(),
%%     Force = boolean()
print_table(Titles, Rows) ->
    print_table(Titles, Rows, false).
print_table(Titles, Rows, Force) ->
    case Force orelse not get(?cfg_quiet) of
        true ->
            print("~s", [table(Rows, Titles)]);
        _ -> nop
    end.

%% @doc Prints value prepended with specified caption
%%      if 'quiet' mode is disabled.
%% @spec print_value(Caption, Value) -> ok
%% @spec print_value(Caption, Value, Force) -> ok
%%     Caption = string(),
%%     Value = term(),
%%     Force = boolean()
print_value(Caption, Value) ->
    print_value(Caption, Value, false).
print_value(Caption, Value, Force) ->
    case Force orelse not get(?cfg_quiet) of
        true ->
            print("~s: ~s~n", [Caption, fmt(Value)]);
        _ -> nop
    end.

print(Format, Args) ->
    case get(?cfg_batch) of
        true ->
            io:format(Format, Args);
        _ ->
            wxTextCtrl:setValue(
              get(?ctl_tab2),
              wxTextCtrl:getValue(
                get(?ctl_tab2)) ++
                  lists:flatten(
                    io_lib:format(Format, Args)))
    end.

%% @doc Format cells to ASCII-art table.
%% @spec table(Rows, Titles) -> string()
%% @spec table(Rows, Titles, Formatter) -> string()
%%     Rows = [Row],
%%         Row = [Cell],
%%         Cell = string(),
%%     Titles = [ColumnTitle],
%%         ColumnTitle = string(),
%%     Formatter = function() of arity 1
table(Rows, Titles) ->
    table(Rows, Titles, fun(T) -> fmt(T) end).
table([H | _] = Rows, Titles, Formatter) ->
    Width = length(H),
    FmtRows =
        lists:map(
          fun(Line) ->
                  lists:map(Formatter, Line)
          end, Rows),
    MaxWidths =
        lists:foldl(
          fun(Line, Maxs) ->
                  lists:map(
                    fun({Str, Max}) ->
                            case length(Str) of
                                N when N > Max -> N;
                                _ -> Max
                            end
                    end, lists:zip(Line, Maxs))
          end, lists:duplicate(Width, 0),
          if is_list(Titles) ->
                  [Titles | FmtRows];
             true -> FmtRows
          end),
    if is_list(Titles) ->
            separator(MaxWidths) ++
                row(MaxWidths, Titles);
       true -> ""
    end ++ separator(MaxWidths) ++
        lists:flatten(
          lists:map(
            fun(Row) ->
                    row(MaxWidths, Row)
            end, FmtRows)) ++
        separator(MaxWidths).

%% @doc table/3 helper function.
%% @spec separator(MaxWidths) -> string()
%%     MaxWidths = [integer()]
separator(MaxWidths) ->
    case get(?cfg_plain) of
        true -> "";
        _ ->
            "+" ++
                string:join(
                  lists:map(
                    fun(W) ->
                            lists:duplicate(W + 2, $-)
                    end, MaxWidths), "+") ++
                "+\n"
    end.

-define(space_char, 32).

%% @doc table/3 helper function.
%% @spec row(MaxWidths, Cells) -> string()
%%     MaxWidths = [integer()]
%%     Cells = [string()]
row(MaxWidths, Cells) ->
    case get(?cfg_plain) of
        true -> string:join(Cells, "\t") ++ "\n";
        _ ->
            "| " ++
                string:join(
                  lists:map(
                    fun({W, Str}) ->
                            case length(Str) of
                                N when N < W ->
                                    Str ++ lists:duplicate(
                                             W - N, ?space_char);
                                _ -> Str
                            end
                    end, lists:zip(MaxWidths, Cells)),
                  " | ") ++ " |\n"
    end.

%% @doc Table cell formatting function.
%% @spec fmt(term()) -> string()
fmt(Int) when is_integer(Int) ->
    lists:flatten(
      io_lib:format("~6.. B", [Int]));
fmt(N) when is_number(N) ->
    Precision =
        case get(?cfg_precision) of
            P when is_integer(P) -> P;
            _ -> ?default_precision
        end,
    %% one for dot, one for sign, three for integer value
    FieldLen = Precision + 5,
    lists:flatten(
      io_lib:format(
        "~" ++ integer_to_list(FieldLen) ++ "." ++
            integer_to_list(Precision) ++ ". f", [N]));
fmt(Term) ->
    case is_string(Term) of
        true -> Term;
        _ ->
            lists:flatten(
              io_lib:format("~9999999p", [Term]))
    end.

%% @doc Returns true if supplied argument looks like string.
%% @spec is_string(String) -> boolean()
%%     String = string()
is_string(List) when is_list(List) ->
    lists:all(fun is_integer/1, List);
is_string(_Term) -> false.

%% ----------------------------------------------------------------------
%% GUI section
%% ----------------------------------------------------------------------

wxcreate_window(Wx) ->
    Frame =
        wxFrame:new(
          Wx, -1, "Pearson product-moment correlation coefficient",
          [{size, {600, 400}}]),
    wxFrame:connect(Frame, close_window),
    MenuBar = wxMenuBar:new(),
    FileM   = wxMenu:new([]),
    HelpM   = wxMenu:new([]),
    _QuitMenuItem  = wxMenu:append(FileM, ?wxID_EXIT, "&Quit"),
    _HelpMenuItem  = wxMenu:append(HelpM, ?wxID_HELP, "&Help"),
    _AboutMenuItem = wxMenu:append(HelpM, ?wxID_ABOUT, "&About...\tF1"),
    ok = wxFrame:connect(Frame, command_menu_selected),
    wxMenuBar:append(MenuBar, FileM, "&File"),
    wxMenuBar:append(MenuBar, HelpM, "&Help"),
    wxFrame:setMenuBar(Frame, MenuBar),
    Panel = wxPanel:new(Frame, []),
    wxPanel:setSizer(Panel, PanelSizer = wxBoxSizer:new(?wxVERTICAL)),
    BtnPanel = wxPanel:new(Panel, []),
    wxPanel:setSizer(BtnPanel,
                     BtnPanelSizer = wxBoxSizer:new(?wxHORIZONTAL)),
    wxSizer:add(BtnPanelSizer,
                BtnOpen = wxButton:new(BtnPanel, ?wxID_OPEN),
                [{flag, ?wxALL}, {border, 2}]),
    wxButton:connect(BtnOpen, command_button_clicked),
    wxSizer:add(BtnPanelSizer,
                BtnRun = wxButton:new(BtnPanel, ?wxID_OK),
                [{flag, ?wxALL}, {border, 2}]),
    wxButton:connect(BtnRun, command_button_clicked),
    wxSizer:add(PanelSizer, BtnPanel),
    PrecPanel = wxPanel:new(Panel, []),
    wxPanel:setSizer(PrecPanel,
                     PrecPanelSizer = wxBoxSizer:new(?wxHORIZONTAL)),
    wxSizer:add(PrecPanelSizer,
                wxStaticText:new(PrecPanel, 1, "Precision:"),
                [{flag,
                  ?wxALIGN_CENTER_VERTICAL bor ?wxLEFT bor ?wxRIGHT},
                 {border, 5}]),
    wxSizer:add(PrecPanelSizer,
                Precision = wxSpinCtrl:new(PrecPanel, [{initial, 4}])),
    wxSpinCtrl:setRange(Precision, 1, 9),
    wxSpinCtrl:setToolTip(Precision, "Results precision (from 1 to 9)"),
    wxSizer:add(PanelSizer, PrecPanel, [{proportion, 0}]),
    Quiet = wxCheckBox:new(
              Panel, ?wxID_ANY,
              "Be quiet (outputs only final results)", []),
    wxSizer:add(PanelSizer, Quiet,
                [{flag, ?wxEXPAND bor ?wxALL},
                 {border, 3}, {proportion, 0}]),
    DrawTables = wxCheckBox:new(
                   Panel, ?wxID_ANY,
                   "Draw tables", []),
    wxCheckBox:setValue(DrawTables, true),
    wxSizer:add(PanelSizer, DrawTables,
                [{flag, ?wxEXPAND bor ?wxALL},
                 {border, 3}, {proportion, 0}]),
    Notebook = wxAuiNotebook:new(
                 Panel,
                 [{style,
                   ?wxAUI_NB_TOP
                       bor ?wxAUI_NB_CLOSE_ON_ACTIVE_TAB
                       bor ?wxAUI_NB_SCROLL_BUTTONS}]),
    wxSizer:add(PanelSizer, Notebook,
                [{flag, ?wxEXPAND}, {proportion, 1}]),
    Tab1 = wxStyledTextCtrl:new(Notebook, []),
    wxStyledTextCtrl:setText(Tab1, "# Type source data here\n\n"),
    wxStyledTextCtrl:setMarginType(Tab1, 0, ?wxSTC_MARGIN_NUMBER),
    LW = wxStyledTextCtrl:textWidth(Tab1, ?wxSTC_STYLE_LINENUMBER, "9"),
    wxStyledTextCtrl:setMarginWidth(Tab1, 0, LW * 4),
    wxStyledTextCtrl:setMarginWidth(Tab1, 1, 0),
    wxStyledTextCtrl:setScrollWidth(Tab1, -1),
    TextFont =
        wxFont:new(
          wxFont:getPointSize(wxWindow:getFont(Tab1)),
          ?wxFONTFAMILY_TELETYPE,
          ?wxFONTSTYLE_NORMAL,
          ?wxFONTWEIGHT_NORMAL),
    wxStyledTextCtrl:styleSetFont(Tab1, ?wxSTC_ERLANG_DEFAULT, TextFont),
    wxAuiNotebook:addPage(Notebook, Tab1, "Source data", []),
    Tab2 = wxTextCtrl:new(Notebook, 1,
                          [{style,
                            ?wxTE_MULTILINE bor
                                ?wxTE_DONTWRAP bor
                                ?wxTE_READONLY}]),
    wxWindow:setFont(Tab2, TextFont),
    wxAuiNotebook:addPage(Notebook, Tab2, "Results", []),
    {Frame,
     Precision, Quiet, DrawTables,
     Notebook, Tab1, Tab2}.

wxloop() ->
    receive 
        #wx{event = #wxClose{}} ->
            wxFrame:destroy(get(?ctl_frame));
        #wx{id = ?wxID_EXIT,
            event = #wxCommand{type = command_menu_selected}} ->
            wxWindow:destroy(get(?ctl_frame));
        #wx{id = ?wxID_ABOUT,
            event = #wxCommand{type = command_menu_selected}} ->
            wxdialog(?wxID_ABOUT),
            wxloop();
        #wx{id = ?wxID_HELP,
            event = #wxCommand{type = command_menu_selected}} ->
            wxdialog(?wxID_HELP),
            wxloop();
        #wx{id = ?wxID_OPEN,
            event = #wxCommand{type = command_button_clicked}} ->
            Dlg = wxFileDialog:new(
                    get(?ctl_frame),
                    [{style,
                      ?wxFD_OPEN bor
                          ?wxFD_FILE_MUST_EXIST bor
                          ?wxFD_PREVIEW}]),
            case wxFileDialog:showModal(Dlg) of
                ?wxID_OK ->
                    wxStyledTextCtrl:loadFile(
                      get(?ctl_tab1), wxFileDialog:getFilename(Dlg)),
                    wxAuiNotebook:setSelection(get(?ctl_notebook), 0),
                    wxTextCtrl:setValue(get(?ctl_tab2), "");
                _ -> nop
            end,
            wxFileDialog:destroy(Dlg),
            wxloop();
        #wx{id = ?wxID_OK,
            event = #wxCommand{type = command_button_clicked}} ->
            put(?cfg_quiet, wxCheckBox:getValue(get(?ctl_quiet))),
            put(?cfg_plain, not wxCheckBox:getValue(get(?ctl_plain))),
            put(?cfg_precision, wxSpinCtrl:getValue(get(?ctl_precision))),
            erase(?input),
            wxTextCtrl:setValue(get(?ctl_tab2), ""),
            case read_input() of
                {ok, PairsCount, Pairs} ->
                    try
                        do_calculations(PairsCount, Pairs),
                        wxAuiNotebook:setSelection(get(?ctl_notebook), 1)
                    catch
                        _:{error, _} -> nop;
                        Type:Reason ->
                            s_error(
                              "Oops! An error of type '~w' occured:~n"
                              "~9999p~n~nStacktrace:~n~p~n~n"
                              "Report source data and this message "
                              "to developer, please.",
                              [Type, Reason, erlang:get_stacktrace()])
                    end;
                _ -> nop
            end,
            wxloop();
        Other ->
            io:format("GUI: got ~p~n", [Other]),
            wxloop()
    end.

wxdialog(?wxID_ABOUT) ->
    Content =
        "Pearson product-moment correlation\n"
        "coefficient calculator.\n\n"
        "Author: Aleksey Morarash <aleksey.morarash@gmail.com>\n"
        "License: FreeBSD\n"
        "Version: 1.0\n",
    Modal =
        wxMessageDialog:new(
          get(?ctl_frame), Content,
          [{style, ?wxOK bor ?wxICON_INFORMATION},
           {caption, "About program"}]),
    wxDialog:showModal(Modal),
    wxDialog:destroy(Modal);
wxdialog(?wxID_HELP) ->
    Modal =
        wxMessageDialog:new(
          get(?ctl_frame), help(),
          [{style, ?wxOK},
           {caption, "Help"}]),
    wxDialog:showModal(Modal),
    wxDialog:destroy(Modal).

