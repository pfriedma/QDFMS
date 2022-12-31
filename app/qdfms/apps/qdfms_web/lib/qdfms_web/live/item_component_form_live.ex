defmodule ItemComponentFormLive do
  use QdfmsWeb, :live_component
  alias Phoenix.LiveView.JS


  def handle_event("validate", _data, socket) do
    {:noreply, socket}

  end


  def handle_event("save_item", %{"item" => item_data} = _data, socket) do
    today = Date.utc_today()
    file_data =
      consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
        #dest = Path.join([:code.priv_dir(:my_app), "static", "uploads", Path.basename(path)])
        # The `static/uploads` directory must exist for `File.cp!/2` to work.
        #File.cp!(path, dest)
        {:ok, Base.encode64(File.read!(path))}
      end)
      encoded_file_data = List.first(file_data)
      if item_data["id"] == "new" do
        IO.puts("creating a new one...")
        upc = if item_data["upc"] != nil && String.length(item_data["upc"]) > 0, do: item_data["upc"], else: nil
        item = %Database.Item{
          upc: upc,
          name: item_data["name"],
          description: item_data["description"],
          mfr_exp_date: Date.from_iso8601!(item_data["exp_date"]),
          date_added: Date.utc_today(),
          weight: ExUc.from(item_data["weight_value"] <> "" <> item_data["units"]),
          container_id: String.to_integer(item_data["container"]),
          photo: encoded_file_data
        }
        case Inventory.Items.create_item(item) do
          {:error, _ } ->
              socket = socket
              |> put_flash(:info, "error")
              {:noreply, socket}
          %Database.Item{} = item ->
            do_assign_categories(item, item_data["categories_checkbox_group"])
            send(self(), {:event, %{update_items: item.id}})
            socket = socket
            {:noreply, socket}
        end
        #do_assign_categories(item.id item_data["categories_checkbox_group"])
      else
        encoded_file_data = if is_nil(encoded_file_data) && item_data["clear_img"] == "false" do
          #need to get the image data as to not replace it
          get_image_from_db(
            Inventory.Items.get_item(
              String.to_integer(item_data["id"])
              )
            )
        else
          encoded_file_data
        end
        item = %Database.Item{
          upc: item_data["upc"],
          id: String.to_integer(item_data["id"]),
          name: item_data["name"],
          description: item_data["description"],
          mfr_exp_date: Date.from_iso8601!(item_data["exp_date"]),
          date_added: Inventory.Items.get_item(String.to_integer(item_data["id"])).date_added,
          weight: ExUc.from(item_data["weight_value"] <> "" <> item_data["units"]),
          container_id: String.to_integer(item_data["container"]),
          photo: encoded_file_data
        }
        case Inventory.Items.update(item) do
          {:error, _ } ->
              socket = socket
              |> put_flash(:info, "error")
              {:noreply, socket}
          %Database.Item{} = item ->
            do_assign_categories(item, item_data["categories_checkbox_group"])
            send(self(), {:event, %{update_items: item.id}})
            socket = socket
            {:noreply, socket}
        end
          {:noreply, socket}
      end
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  defp get_image_from_db(%Database.Item{} = item) do
    item.photo
  end

  defp do_assign_categories(item, cat_list) do
      cat_list = if is_nil(cat_list) || Enum.count(cat_list) == 0 do
        []
      else
        Enum.map(cat_list, fn x -> String.to_integer(x) end)
      end
      Inventory.Items.update_categories_item(item.id, cat_list)
  end


  def render(assigns) do

    ~H"""
    <div class="item_form">

    <%= f = form_for :item, "#",  phx_submit: "save_item", phx_change: "validate", phx_target: @myself %>
      <% cats = if @id != "new", do: Enum.map(Inventory.Items.get_categories_raw(String.to_integer(@id)), fn %Database.ItemCategory{} = x -> x.category_id end), else: [@item_categories]%>
      <%= hidden_input f, :id, value: @id %>
      <%= hidden_input f, :container, value: @container%>
        <%= label f, :name %>
        <%= text_input f, :name, value: @item.name %>
        <%= error_tag f, :name %>
        <%= unless is_nil(@item.upc) || String.length(@item.upc) == 0 do %>
          <%= label f, :upc  %>
          <%= text_input f, :upc, value: @item.upc %>
          <%= error_tag f, :upc %>
        <% end %>
        <%= label f, :description %>
        <%= text_input f, :description, value: @item.description %>
        <%= error_tag f, :description %>

        <%= label f, :exp_date %>
        <%= date_input f, :exp_date, value: @item.mfr_exp_date %>

        <%= label f, :weight %>
        <%= number_input f, :weight_value, value: @item.weight.value %>
        <%= label f, :units %>
        <%= select f, :units, Enum.map(ExUc.Units.Mass.units, fn {x,y} -> x end), value: @item.weight.unit %>
        <%= #multiple_select(f, :categories_select_multiple, Enum.map(Inventory.Category.get_all_categories(), fn x -> x.id end) ) %>
        <fieldset id="categories_checkbox_group">
        <%= for cat <-  Inventory.Category.get_all_categories() do  %>
            <div class="categories">
            <%= if !is_nil(cat.image) do %>
            <img src={"data:image/svg+xml;base64,#{cat.image}"}, height='60', width='60'/><br/>
            <% end %>
            <input type="checkbox" name="item[categories_checkbox_group][]" value={cat.id} checked={Enum.member?(cats,cat.id)}/><%=cat.name %>
            </div>
        <% end %>
      </fieldset>
      <%= label f, :image %>
      <%= live_file_input @uploads.image %>
      <%= unless @id == "new" do%>
        <%= label f, "Clear Image?" %>
        <%= checkbox f, :clear_img %>
      <% end %>
      <div style="clear:both"></div>


    <%= submit "Save" %>
    </div>
    """
  end


end
