defmodule PhoenixAuthWeb.UserLive.Login do
  use PhoenixAuthWeb, :live_view

  alias PhoenixAuth.Accounts
  import Phoenix.LiveView.Helpers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex justify-center items-center min-h-screen bg-gray-50">
        <div class="bg-white shadow-md rounded-lg w-full max-w-md p-8 space-y-6">
          <div class="text-center">
            <h1 class="text-2xl font-bold text-gray-800">Log in</h1>
            <p class="mt-2 text-sm text-gray-600">
              <%= if @current_scope do %>
                Reauthenticate to continue.
              <% else %>
                Don't have an account? <.link
                  navigate={~p"/users/register"}
                  class="text-blue-600 font-semibold hover:underline"
                  phx-no-format
                >Sign up</.link>
              <% end %>
            </p>
          </div>

          <%= if local_mail_adapter?() do %>
            <div class="bg-blue-50 border-l-4 border-blue-400 p-4 text-blue-700 text-sm rounded-md">
              You are running the local mail adapter.
              Visit <.link href="/dev/mailbox" class="underline">the mailbox</.link>
              to see sent emails.
            </div>
          <% end %>
          
    <!-- Magic link form -->
          <.form
            :let={f}
            for={@form}
            id="login_form_magic"
            action={~p"/users/log-in"}
            phx-submit="submit_magic"
            class="space-y-4"
          >
            <.input
              readonly={!!@current_scope}
              field={f[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              required
              phx-mounted={JS.focus()}
              class="input input-bordered w-full"
            />
            <.button class="w-full bg-blue-600 text-white font-semibold py-2 rounded hover:bg-blue-700">
              Log in with Email <span aria-hidden="true">→</span>
            </.button>
          </.form>

          <div class="flex items-center my-4">
            <hr class="flex-grow border-gray-300" />
            <span class="mx-2 text-gray-400 text-sm">or</span>
            <hr class="flex-grow border-gray-300" />
          </div>
          
    <!-- Password login -->
          <.form
            :let={f}
            for={@form}
            id="login_form_password"
            action={~p"/users/log-in"}
            phx-submit="submit_password"
            phx-trigger-action={@trigger_submit}
            class="space-y-4"
          >
            <.input
              readonly={!!@current_scope}
              field={f[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              required
              class="input input-bordered w-full"
            />
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              autocomplete="current-password"
              class="input input-bordered w-full"
            />
            <div class="flex items-center justify-between text-sm text-gray-600">
              <label class="flex items-center space-x-2">
                <input
                  type="checkbox"
                  class="form-checkbox"
                  name={@form[:remember_me].name}
                  value="true"
                />
                <span>Remember me</span>
              </label>
              <.link navigate={~p"/users/reset-password"} class="hover:underline text-blue-600">
                Forgot password?
              </.link>
            </div>
            <.button class="w-full bg-blue-600 text-white font-semibold py-2 rounded hover:bg-blue-700">
              Log in <span aria-hidden="true">→</span>
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:phoenix_auth, PhoenixAuth.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
