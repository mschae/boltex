defmodule Boltex.PackStream.Message do
  @callback signature() :: number()
  @callback list_data(struct()) :: [term]
end

defmodule Boltex.PackStream.Message.Init do
  @moduledoc """
  This module holds data and functions required dor INIT message
  """

  @behaviour Boltex.PackStream.Message

  @client_name "Boltex/0.4.0"
  @signature 0x01

  defstruct client_name: @client_name, auth_token: %{}

  @doc """
  Returns the INIT message signature
  """
  def signature() do
    @signature
  end

  @doc """
  Build a list of data from Init structure
  """
  def list_data(%{client_name: client_name, auth_token: auth_token}) do
    [client_name, auth_token]
  end
end

defmodule Boltex.PackStream.Message.AckFailure do
  @moduledoc """
  This module holds data and functions required dor ACK_FAILURE message
  """

  @behaviour Boltex.PackStream.Message

  @signature 0x0E

  defstruct []

  @doc """
  Returns the ACK_FAILURE message signature
  """
  def signature() do
    @signature
  end

  @doc """
  Build a list of data from AckFailure structure
  """
  def list_data(_) do
    []
  end
end

defmodule Boltex.PackStream.Message.Run do
  @moduledoc """
  This module holds data and functions required for RUN message
  """

  @behaviour Boltex.PackStream.Message

  @signature 0x10

  defstruct [:statement, :parameters]

  @doc """
  Returns the RUN message signature
  """
  def signature() do
    @signature
  end

  @doc """
  Build a list of data from Run structure
  """
  def list_data(%{statement: statement, parameters: parameters}) do
    [statement, parameters]
  end
end

defmodule Boltex.PackStream.Message.PullAll do
  @moduledoc """
  This module holds data and functions required for PULL_ALL message
  """

  @behaviour Boltex.PackStream.Message

  @signature 0x3F

  defstruct []

  @doc """
  Returns the PULL_ALL message signature
  """
  def signature() do
    @signature
  end

  @doc """
  Build a list of data from PullAll structure
  """
  def list_data(_) do
    []
  end
end

defmodule Boltex.PackStream.Message.DiscardAll do
  @moduledoc """
  This module holds data and functions required for DISCARD_ALL message
  """

  @behaviour Boltex.PackStream.Message

  @signature 0x2F

  defstruct []

  @doc """
  Returns the DISCARD_ALL message signature
  """
  def signature() do
    @signature
  end

  @doc """
  Build a list of data from DiscardAll structure
  """
  def list_data(_) do
    []
  end
end

defmodule Boltex.PackStream.Message.Reset do
  @moduledoc """
  This module holds data and functions required for RESET message
  """

  @behaviour Boltex.PackStream.Message

  @signature 0x0F

  defstruct []

  @doc """
  Returns the RESET message signature
  """
  def signature() do
    @signature
  end

  @doc """
  Build a list of data from Reset structure
  """
  def list_data(_) do
    []
  end
end
