defmodule Level.SvgTest do
  use Level.DataCase, async: true

  alias Level.Svg

  describe "to_elm/1" do
    test "handles blank input" do
      assert {:ok, ""} = Svg.to_elm("")
    end

    test "converts svg to Elm" do
      svg = ~s{
        <svg width="20px" height="20px" viewBox="0 0 20 20" version="1.1">
          <g id="Page-1" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round">
            <g id="search" transform="translate(1.000000, 1.000000)" stroke="#8A98A5" stroke-width="2">
              <circle id="Oval" cx="8" cy="8" r="8"></circle>
              <path d="M18,18 L13.65,13.65" id="Shape"></path>
            </g>
          </g>
        </svg>
      }

      expected = ~s{
        svg [ width "20px", height "20px", viewBox "0 0 20 20", version "1.1" ] [ g [ id "Page-1", stroke "none", strokeWidth "1", fill "none", fillRule "evenodd", strokeLinecap "round", strokeLinejoin "round" ] [ g [ id "search", transform "translate(1.000000, 1.000000)", stroke "#8A98A5", strokeWidth "2" ] [ circle [ id "Oval", cx "8", cy "8", r "8" ] [], Svg.path [ d "M18,18 L13.65,13.65", id "Shape" ] [] ] ] ]
      }

      {:ok, result} = Svg.to_elm(svg)
      assert_trimmed_equal(result, expected)
    end

    test "ignores non-svg nodes" do
      svg = ~s{
        <?xml version="1.0" encoding="UTF-8"?>
        <svg>
        </svg>
      }

      expected = ~s{
        svg [] []
      }

      {:ok, result} = Svg.to_elm(svg)
      assert_trimmed_equal(result, expected)
    end
  end

  def assert_trimmed_equal(a, b) do
    assert String.trim(a) == String.trim(b)
  end
end
