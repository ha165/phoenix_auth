defmodule PhoenixAuth.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :first_name, :string
    field :last_name, :string
    field :DOB, :date

    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true

    field :confirmed_at, :utc_datetime_usec
    field :authenticated_at, :utc_datetime, virtual: true

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Registration changeset for new users.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :DOB, :email])
    |> validate_required([:first_name, :last_name, :DOB, :email])
    |> validate_length(:first_name, max: 50)
    |> validate_length(:last_name, max: 50)
    |> validate_dob()
    |> validate_email()
  end

  @doc """
  A changeset for updating the email.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  @doc """
  A changeset for updating the password.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    change(user, confirmed_at: DateTime.utc_now())
  end

  # ---- PRIVATE HELPERS ----

  defp validate_email(changeset, opts \\ []) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, PhoenixAuth.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  defp validate_password(changeset, opts \\ []) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp validate_dob(changeset) do
    validate_change(changeset, :DOB, fn :DOB, dob ->
      if Date.compare(dob, Date.utc_today()) == :gt do
        [DOB: "cannot be in the future"]
      else
        []
      end
    end)
  end

  @doc """
  Verifies a password for a given user.
  """
  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _), do: Bcrypt.no_user_verify() && false
end
