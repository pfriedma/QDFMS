defmodule QdfmsWeb.AdminLive do
  use QdfmsWeb, :live_view
  alias Phoenix.LiveView.JS
  alias Database.Category
  #@topic "whats_inside"

  # OTP Auth code should eventually move elsewhere, it doesn't belong in the LiveView
  @secret "CHANGEME1337"

  @def_states [
      home: %{active: true, display: "Home", help: "Home", action: "reset"},
      containers: %{active: false, display: "Containers", help: "Container management", action: "do_container_admin"},
      categories: %{active: false, display: "Categories", help: "Manage Item Categories", action: "do_cat_mgmt"},
      devices: %{active: false, display: "Endpoint Devices", help: "Manage devices used to manage inventory items", action: "do_dev_mgmt"}
    ]



  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
          |> check_first_run
          |> assign(:state, @def_states)
          |> assign(:inf_data, %{})
          |> assign(:uploaded_files, [])
          |> allow_upload(:icon, accept: ~w(.svg), auto_upload: false),
        temporary_assigns: [inf_data: %{}]
      }  # add items to assigns
  end

  @impl true
  def handle_event("reset", data, socket) do
      socket = socket
      |> change_state(:home)
      {:noreply, socket}
  end

  def handle_event("do_cat_mgmt", data, socket) do
      socket = socket
      |> assign(:inf_data, %{categories: Inventory.Category.get_all_categories()})
      |> change_state(:categories)
      {:noreply, socket}
  end

  def handle_event("do_container_admin", _data, socket) do
      socket = socket
      |> assign(:inf_data, %{containers: Inventory.Container.get_all_containers()})
      |> change_state(:containers)
      {:noreply, socket}
  end

  def handle_event("do_dev_mgmt", _data, socket) do
    {:noreply,
        socket
        |> assign(:inf_data, %{devices: Inventory.Device.get_all_devices()})
        |> change_state(:devices)
    }
  end


  def handle_info({:updated_categories}, socket) do
    # update books list, the selected categories and the changeset
    {:noreply, socket |> assign(:inf_data, %{categories: Inventory.Category.get_all_categories()})}
  end

  def handle_info({:updated_devices}, socket) do
    # update books list, the selected categories and the changeset
    {:noreply, socket |> assign(:inf_data, %{devices: Inventory.Device.get_all_devices()})}
  end

  def handle_info({:updated_containers}, socket) do
    # update books list, the selected categories and the changeset
    {:noreply, socket |> assign(:inf_data, %{containers: Inventory.Container.get_all_containers()})}

  end
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  defp firstrun(socket) do
    false
  end

  defp change_state(socket, active_state) do
      states_kwl = socket.assigns.state
      new_state = Enum.map(states_kwl, fn {key, map} ->
        {key, Map.replace(map, :active, key == active_state)} end)
      assign(socket, state: new_state)
  end

  defp check_first_run(socket) do
    if firstrun(socket) do
      assign(socket, firstrun: true)
    else
      socket
    end
  end


  @impl true
  def render(assigns) do
    ~H"""

    <style>
      #nav {border: 1px solid black; clear:both;}
      .nav_item {display: inline-block;}
      .nav_item button {
        background-color: grey;
        border: none;
        color: white;
        text-align: center;
        text-decoration: none;
        display: inline-block;
        transition-duration: 0.4s;
        font-size: 16px;
      }
      .nav_item button:hover {
          background-color: #4CAF50;
      }
      .nav_item .disabled {
        opacity: 0.6;
        cursor: not-allowed;
      }
      .nav_item .selected {
        background-color: blue;
      }
    </style>

    <%= unless is_nil(@state) do %>
    <div id = "nav">
        <%= for {state_atom, state_map} <- @state do %>
          <div class="nav_item">
            <button id={to_string(state_atom)} phx-click={state_map[:action]} class={if state_map[:active], do: "selected", else: ""}>
              <%=state_map[:display]%>
            </button>
          </div>


        <% end %>
    </div>
    <% end %>

    <div id = "main_window", style="clear:both">
      <div id = "app" >
        <div class="alert" phx-click="lv:clear-flash" phx-value-key="info">
          <%= live_flash(@flash, :info) %>
        </div>
          <%= if @state[:categories][:active] do %>
              <%= render_category_screen(assigns) %>
          <% end %>
          <%= if @state[:containers][:active] do %>
              <%= render_container_screen(assigns) %>
          <% end %>
          <%= if @state[:devices][:active] do %>
            <%= render_device_screen(assigns) %>
          <% end %>
      </div>
            <%= Kernel.inspect(@state) %>
            <%= Kernel.inspect(@inf_data) %>

    </div>
    """
  end


  defp render_device_screen(assigns) do
    ~H"""

    <h1> Manage Devices </h1>
    <button phx-click={JS.show(to: "#new_device_form", transition: "fade-in")}>Create New</button>
    <div id="new_device_form" hidden data-js-exec={JS.hide(to: "#new_device_form", transition: "fade-out")}>
      <.live_component module={DeviceFormComponent} id="new" id_token="" container_id="" containers={Inventory.Container.get_all_containers()} />
      <button phx-click={JS.hide(to: "#new_device_form", transition: "fade-out")}>Cancel</button>
    </div>
    <%= unless is_nil(@inf_data[:devices]) do %>
    <%= for dev <- @inf_data[:devices] do %>
          <div class="devices">
          <% container = Inventory.Container.get_container(dev.container_id) %>
          Container: <%=container.name %><br/>
          Device ID: <%=dev.device_id %><br/>
          <div class="modal-edit-box" id={"dev-modal-" <> to_string(dev.id)}, hidden >

              <h1> editing for <%= dev.device_id %> </h1>
              <.live_component module={DeviceFormComponent} id={dev.id} id_token={dev.device_id} container_id={dev.container_id} containers={Inventory.Container.get_all_containers()} />

          </div>
          <button phx-click={JS.toggle(to: "#dev-modal-#{to_string(dev.id)}", in: "fade-in", out: "fade-out")} > Edit </button>
          </div>

    <% end %>
    <% end %>

    """
  end


  defp render_container_screen(assigns) do
    ~H"""
    <%= unless is_nil(@inf_data[:containers]) do %>
    <h1> Manage Containers </h1>
    <button phx-click={JS.show(to: "#new_container_form", transition: "fade-in")}>Create New</button>
    <div id="new_container_form" hidden data-js-exec={JS.hide(to: "#new_container_form", transition: "fade-out")}>
      <.live_component module={ContainerFormComponent} id="new" name="" />
      <button phx-click={JS.hide(to: "#new_container_form", transition: "fade-out")}>Cancel</button>
    </div>
    <%= for cont <- @inf_data[:containers] do %>
          <div class="containers">
          <%=cont.name %><br/>
          <button> Show Items </button>
          </div>

      <% end %>


    <% end %>

    """
  end

  defp render_category_screen(assigns) do
    ~H"""
    <div id="category_screen" >
      <h1> Manage Categories </h1>
      <button phx-click={JS.show(to: "#new_category_form", transition: "fade-in")}>Create New</button>
      <div id="new_category_form" hidden data-js-exec={JS.hide(to: "#new_category_form", transition: "fade-out")}>
        <.live_component module={CategoryFormComponent} id="new" name="" uploads={@uploads} />
      </div>
      <%= unless is_nil(@inf_data[:categories]) do %>
        <%= for cat <- @inf_data[:categories] do %>
          <div class="categories">
          <%= if !is_nil(cat.image) do %>
          <img src={"data:image/svg+xml;base64," <> cat.image}, height='60', width='60'/><br/>
          <% end %>
          <%= cat.name %>
          <div class="modal-edit-box" id={"cat-modal-" <> to_string(cat.id)}, hidden >

              <h1> editing for <%= cat.name %> </h1>
              <.live_component module={CategoryFormComponent} id={cat.id} name={cat.name} uploads={@uploads} />

          </div>

          <button phx-click={JS.toggle(to: "#cat-modal-#{to_string(cat.id)}", in: "fade-in", out: "fade-out")} > Edit </button>
          </div>

        <% end %>
      <% end %>
    </div>
    """
  end

end
