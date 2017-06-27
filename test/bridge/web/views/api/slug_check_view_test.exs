defmodule Bridge.Web.API.SlugCheckViewTest do
  use Bridge.Web.ConnCase, async: true

  alias Bridge.Web.API.SlugCheckView

  describe "render/2 create.json" do
    test "renders the response" do
      assert SlugCheckView.render("create.json", %{valid: true}) ==
        %{valid: true}
    end
  end
end
