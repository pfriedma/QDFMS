defmodule ContainerFormComponent do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_component
  use QdfmsWeb, :live_component
  alias Database.Container



  def handle_event("validate", _data, socket) do
    {:noreply, socket}

  end

  def handle_event("save_container", %{"container" => cont_data} = _data, socket) do
    IO.puts("in the component!")

      if cont_data["id"] == "new" do
        IO.puts("creating a new one...")
        Inventory.Container.create_container(cont_data["name"])
        send(self(), {:updated_containers})
        socket = socket
        |> put_flash(:info, "container added!")
        {:noreply, socket}

      else
        {:noreply, socket}
      end
  end



  def render(assigns) do
    ~H"""
    <div class="container_form">

      <%= f = form_for :container, "#", phx_submit: "save_container", phx_change: "validate", phx_target: @myself %>
      <%= hidden_input f, :id, value: @id %>
      <%= label f, :name, value: @name %>
      <%= text_input f, :name, value: @name %>
      <%= submit "Save", phx_disable_with: "Saving..." %>
    </div>
    """
  end

end
