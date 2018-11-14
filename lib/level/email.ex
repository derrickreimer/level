defmodule Level.Email do
  @moduledoc """
  Transactional emails.
  """

  use Bamboo.Phoenix, view: LevelWeb.EmailView

  alias Level.Digests.Digest
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

  @doc """
  Generates a digest email.
  """
  @spec digest(Digest.t()) :: Bamboo.Email.t()
  def digest(%Digest{} = digest) do
    base_digest_email()
    |> to(digest.to_email)
    |> subject(digest.subject)
    |> assign(:subject, digest.subject)
    |> assign(:preheader, "")
    |> assign(:digest, digest)
    |> render(:digest)
    |> inline_styles()
  end

  defp base_email do
    new_email()
    |> from("Level Support <support@level.app>")
    |> put_html_layout({LayoutView, "plain_text_email.html"})
  end

  defp base_digest_email do
    new_email()
    |> from("Level <support@level.app>")
    |> put_html_layout({LayoutView, "branded_email.html"})
  end

  defp inline_styles(email) do
    html = Premailex.to_inline_css(email.html_body)

    email
    |> html_body(html)
  end
end
