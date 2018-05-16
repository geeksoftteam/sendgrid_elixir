defmodule SendGrid.Contacts.Recipients do
  @moduledoc """
  Module to interact with modifying contacts.

  See [SendGrid's Contact API Docs](https://sendgrid.com/docs/API_Reference/Web_API_v3/Marketing_Campaigns/contactdb.html)
  for more detail.
  """

  require Logger

  @base_api_url "/v3/contactdb/recipients"

  @doc """
  Adds a contact to the contacts list available in Marketing Campaigns. At a minimum, an email address must provided.
  Additionaly, custom fields that have already been created can added as well.

      {:ok, recipient_id} = add("test@example.com", %{"name" => "John Doe"})

      {:ok, recipient_id} = add("test@example.com")
  """
  @spec add(String.t, %{}) :: { :ok, String.t } | { :error, list(String.t) }
  def add(email_address, custom_fields \\ %{}) do
    payload = Map.merge(%{"email" => email_address}, custom_fields)

    SendGrid.post(@base_api_url, [payload])
    |> handle_recipient_result
  end

  @doc """
  Adds or updates multiple recipients in contacts list.
  Recipients param must be in format required by Sendgrid:
    [
      %{
        "email" => "test@example.com",
        "name"  => "John Doe",
        etc...
      }
    ]
  """
  @spec add_multiple([]) :: { :ok, [] } | { :ok, String.t } | { :error, list(String.t) }
  def add_multiple(recipients) when is_list(recipients) do
    SendGrid.patch(@base_api_url, recipients)
    |> handle_recipient_result
  end

  @doc """
  Allows you to perform a search on all of your Marketing Campaigns recipients

      {:ok, recipients} = search(%{"first_name" => "test"})
  """
  @spec search(map) :: { :ok, list(map) } | { :error, list(String.t) }
  def search(opts) do
    query = URI.encode_query(opts)
    SendGrid.get("#{@base_api_url}/search?#{query}")
    |> handle_search_result
  end

  # Handles the result when there are multiple persisted recipients.
  defp handle_recipient_result({:ok, %{body: %{"persisted_recipients" => recipients}}}) when is_list(recipients) and length(recipients) > 1 do
    { :ok, recipients }
  end
  # Handles the result when errors are present.
  defp handle_recipient_result({:ok, %{body: body = %{"error_count" => count}}}) when count > 0 do
    errors =
      body["errors"]
      |> Enum.map(fn error -> error["message"] end)

    {:error, errors}
  end
  # Handles the result when it's valid.
  defp handle_recipient_result({:ok, %{body: %{"persisted_recipients" => [recipient_id]}}}) do
    { :ok, recipient_id }
  end
  # Handles the result when there were no returned recipients (for example if it's an update which didn't change anything)
  defp handle_recipient_result({:ok, %{body: %{"persisted_recipients" => []}}}) do
    { :error, [ "No changes applied for recipient" ] }
  end
  defp handle_recipient_result(error) do
    Logger.error "Unhandled response from SendGrid - #{inspect error}"
    { :error, [ "Unexpected error" ] }
  end

  # Handles the result when it's valid.
  defp handle_search_result({:ok, %{body: body = %{"error_count" => count }}}) when count > 0 do
    errors =
      body["errors"]
      |> Enum.map(fn(error) -> error["message"] end)

    { :error, errors }
  end
  defp handle_search_result({:ok, %{body: %{"recipients" => recipients}}}) do
    { :ok, recipients }
  end
  defp handle_search_result(error) do
    Logger.error "Unhandled response from SendGrid - #{inspect error}"
    { :error, [ "Unexpected error" ] }
  end

end
