defmodule Inventory.Device do
  require Amnesia
  require Amnesia.Helper
  require Exquisite
  require Database.RegisteredDevice
  alias Database.RegisteredDevice

  #  deftable(
  #  RegisteredDevice,
  #  [{:id, autoincrement}, :device_id, :container_id],
  #  type: :set,
  #  index: [:device_id]
  #   )
  #
  def create_device(id_token, container) do
    Amnesia.transaction do
      %RegisteredDevice{device_id: id_token, container_id: container}
      |> RegisteredDevice.write()
    end
  end

  def update_device(id, id_token, container) do
    case get_device(id) do
      {:error, _} -> {:error, :not_found}
      %RegisteredDevice{} = device ->
        Amnesia.transaction do
          device
          |> Map.update!(:device_id, &(&1 = id_token))
          |> Map.update!(:container_id, &(&1 = container))
          |> RegisteredDevice.write()
        end
    end
  end

  def get_device(id) do
    Amnesia.transaction do
      RegisteredDevice.read(id)
    end
    |> case do
      %RegisteredDevice{} = device-> device
      _ -> {:error, :not_found}
    end
  end

  def find_device_by_idtoken(id_token) do
    Amnesia.transaction do
      RegisteredDevice.where(device_id == id_token)
      |> Amnesia.Selection.values()
    end
  end

  def get_all_devices() do
    Amnesia.transaction do
      RegisteredDevice.stream()
      |> Enum.to_list
    end
  end



end
