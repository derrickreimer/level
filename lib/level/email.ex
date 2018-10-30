defmodule Level.Email do
  @moduledoc """
  Transactional emails.
  """

  use Bamboo.Phoenix, view: LevelWeb.EmailView

  alias Level.Schemas.PasswordReset
  alias Level.Schemas.User
  alias LevelWeb.LayoutView

  @doc """
  Generates a password reset email.
  """
  @spec password_reset(User.t(), PasswordReset.t()) :: Bamboo.Email.t()
  def password_reset(%User{} = user, %PasswordReset{} = reset) do
    base_email()
    |> to(user.email)
    |> subject("Reset your Level password")
    |> assign(:password_reset, reset)
    |> render(:password_reset)
  end

  defp base_email do
    new_email()
    |> from("Level Support <support@level.app>")
    |> put_html_layout({LayoutView, "plain_text_email.html"})
  end
end
