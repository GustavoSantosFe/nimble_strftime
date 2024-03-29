defmodule NimbleStrftimeTest do
  use ExUnit.Case
  doctest NimbleStrftime

  describe "format/3" do
    test "return received string if there is no datetime formatting to be found in it" do
      assert NimbleStrftime.format(~N[2019-08-20 15:47:34.001], "muda string") == "muda string"
    end

    test "format all time zones blank when receiving a NaiveDateTime" do
      assert NimbleStrftime.format(~N[2019-08-15 17:07:57.001], "%z%Z") == ""
    end

    test "raise error when trying to format a date with a map that has no date fields" do
      time_without_date = %{hour: 15, minute: 47, second: 34, microsecond: {0, 0}}

      assert_raise(KeyError, fn -> NimbleStrftime.format(time_without_date, "%x") end)
    end

    test "raise error when trying to format a time with a map that has no time fields" do
      date_without_time = %{year: 2019, month: 8, day: 20}

      assert_raise(KeyError, fn -> NimbleStrftime.format(date_without_time, "%X") end)
    end

    test "raise error when the format is invalid" do
      assert_raise(FunctionClauseError, fn ->
        NimbleStrftime.format(~N[2019-08-20 15:47:34.001], "%-2-ç")
      end)
    end

    test "raise error when the preferred_datetime calls itself" do
      assert_raise(RuntimeError, fn ->
        NimbleStrftime.format(~N[2019-08-20 15:47:34.001], "%c", preferred_datetime: "%c")
      end)
    end

    test "raise error when the preferred_date calls itself" do
      assert_raise(RuntimeError, fn ->
        NimbleStrftime.format(~N[2019-08-20 15:47:34.001], "%x", preferred_date: "%x")
      end)
    end

    test "raise error when the preferred_time calls itself" do
      assert_raise(RuntimeError, fn ->
        NimbleStrftime.format(~N[2019-08-20 15:47:34.001], "%X", preferred_time: "%X")
      end)
    end

    test "raise error when the preferred formats create a circular chain" do
      assert_raise(RuntimeError, fn ->
        NimbleStrftime.format(~N[2019-08-20 15:47:34.001], "%c",
          preferred_datetime: "%x",
          preferred_date: "%X",
          preferred_time: "%c"
        )
      end)
    end

    test "format with no errors is the preferred formats are included multiple times on the same string" do
      assert(
        NimbleStrftime.format(~N[2019-08-15 17:07:57.001], "%c %c %x %x %X %X") ==
          "2019-08-15 17:07:57 2019-08-15 17:07:57 2019-08-15 2019-08-15 17:07:57 17:07:57"
      )
    end

    test "return `hour:minute:seconds PM` when receiving `%I:%M:%S %p`" do
      assert NimbleStrftime.format(~U[2019-08-15 17:07:57.001Z], "%I:%M:%S %p") == "05:07:57 PM"
    end

    test "ignore width when receiving the `-` padding option" do
      assert NimbleStrftime.format(~T[17:07:57.001], "%-999M") == "7"
    end

    test "format time zones correctly when receiving a DateTime" do
      datetime_with_zone = %DateTime{
        year: 2019,
        month: 8,
        day: 15,
        zone_abbr: "EEST",
        hour: 17,
        minute: 7,
        second: 57,
        microsecond: {0, 0},
        utc_offset: 7200,
        std_offset: 3600,
        time_zone: "UK"
      }

      assert NimbleStrftime.format(datetime_with_zone, "%z %Z") == "+0300 EEST"
    end

    test "return the formatted datetime when all format options and modifiers are received" do
      assert NimbleStrftime.format(
               ~U[2019-08-15 17:07:57.001Z],
               "%04% %a %A %b %B %-3c %d %f %H %I %j %m %_5M %p %P %q %S %u %x %X %y %Y %z %Z"
             ) ==
               "000% Thu Thursday Aug August 2019-08-15 17:07:57 15 1000 17 05 227 08     7 PM pm 3 57 04 2019-08-15 17:07:57 19 2019 +0000 UTC"
    end

    test "format according to received custom configs" do
      assert NimbleStrftime.format(
               ~U[2019-08-15 17:07:57.001Z],
               "%A %p %B %c %x %X",
               am_pm_names: {"a", "p"},
               month_names:
                 ~w(Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro),
               day_of_week_names:
                 ~w(понедельник вторник среда четверг пятница суббота воскресенье),
               preferred_date: "%05Y-%m-%d",
               preferred_time: "%M:%_3H%S",
               preferred_datetime: "%%"
             ) == "четверг P Agosto % 02019-08-15 07: 1757"
    end
  end
end
