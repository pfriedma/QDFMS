defmodule DeviceFormComponent do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_component
  use QdfmsWeb, :live_component
  alias Database.RegisteredDevice



  def handle_event("validate", _data, socket) do
    {:noreply, socket}

  end



  def handle_event("save_device", %{"device" => dev_data} = _data, socket) do
    IO.puts("in the component!")
      cont_id = String.to_integer(dev_data["container"])
      if dev_data["id"] == "new" do
        IO.puts("creating a new one...")
        Inventory.Device.create_device(dev_data["id_token"], cont_id)
        send(self(), {:updated_devices})
        socket = socket
        |> put_flash(:info, "Device added!")
        {:noreply, socket}

      else
        IO.puts("updating device " <> dev_data["id"])
        id = String.to_integer(dev_data["id"])
        case Inventory.Device.update_device(id, dev_data["id_token"], cont_id) do
            {:error, reason} ->
              {:noreply,
              socket
              |> put_flash(:info, "ERROR "<> to_string(reason))
              }

            %RegisteredDevice{} = device ->
              send(self(), {:updated_devices})
              {:noreply,
              socket
              |> push_event("js-exec", %{id: "#edit_device_form-#{dev_data[id]}"})
              |> put_flash(:info, "device " <> dev_data["id_token"] <> " added!")
              }

            _ -> {:noreply,
            socket
            |> put_flash(:info, "ERROR - unrecognised response")
            }
          end


      end
  end



  def render(assigns) do
    ~H"""
    <div class="device_form">
      <%= f = form_for :device, "#", phx_submit: "save_device", phx_change: "validate", phx_target: @myself %>
      <%= hidden_input f, :id, value: @id %>
      <%= label f, :id_token %>
      <%= text_input f, :id_token, value: @id_token %>
      <%= select f, :container, Enum.map(@containers, &{&1.name, &1.id}), value: @container_id%>
      <%= submit "Save", phx_disable_with: "Saving..." %>
    </div>
    """
  end

end
